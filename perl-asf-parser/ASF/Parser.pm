package ASF::Parser;
use strict;
use warnings;
use bytes;

use ASF::Spec;
use ASF::Parser::Response;

use Carp qw(confess);
use Encode qw(decode);
use Time::Piece ();

sub new {
    my $class = shift;
    bless +{ spec => ASF::Spec->new() }, $class;
}

sub spec { shift->{spec} }

sub can_parse {
    my ( $self, $data ) = @_;
    if ( defined $data ) {
        my $len = length($data);
           0 <= $len
        && 4 <= $len
        && $self->_unpack( substr($data, 0, 2), 2 ) == 0x4824
        && $self->_unpack( substr($data, 2, 2), 2 ) <= length( substr($data, 4) );
    }
    else {
        0;
    }
}

sub parse {
    my ( $self, $data ) = @_;

    my $header_data = substr( $data, 12, $self->_unpack( substr($data, 28, 8), 8 ) );
    my ($object, $parsed) = $self->_parse( $header_data, $self->spec->structure );

    ASF::Parser::Response->new( $object );
}

sub _parse {
    my ( $self, $data, $struct, $limit ) = @_;

    my $rstruct = ref $struct;
    my ($obj, $pos, $ldata) = (+{}, 0, length($data));
    confess unless $rstruct eq 'ARRAY' || $rstruct eq 'HASH';

    # [ @fields ]
    if ( $rstruct eq 'ARRAY' ) {
        foreach my $field (@$struct) {
            confess unless ref($field) eq 'ARRAY';

            my ( $name,  $size,  $type  ) = @$field;
            my ( $rname, $rsize, $rtype ) = map { ref $_ } ( $name,  $size,  $type );
            confess unless $rname eq '';

            # name => size
            if ( $rsize ne 'ARRAY' ) {
                confess unless $rtype eq '' || $rtype eq 'ARRAY' || $rtype eq 'HASH';

                my $size = $rsize eq 'SCALAR' ? $obj->{ $$size }
                         : defined $size      ? $size / 8
                                              : $ldata - $pos;

                my $value = do {
                    # 8, 16, 32, 64, 128
                    if ( int($size) == $size && int($pos) == $pos ) {
                        substr( $data, $pos, $size );
                    }
                    # other (Flag)
                    elsif ( $rtype eq '' ) {
                        ( unpack('C*', $data) >> $pos*8 ) & ( 2**($size*8)-1  );
                    }
                    else {
                        confess;
                    }
                };

                # name => size => type/undef
                if ( $rtype eq '' ) {   # allow undef
                    $obj->{$name} = $self->_unpack( $value, $size, $type );
                    $obj->{$name} = '' if $name eq 'Padding Data';
                }

                # name => size =>  []
                elsif ( $rtype eq 'ARRAY' ) {
                    my ( $sub_obj, $parsed ) = $self->_parse( $value, $type );
                    confess unless $parsed == $size;
                    $obj->{$name} = $sub_obj;
                }

                # name => size => +{}
                elsif ( $rtype eq 'HASH' ) {

                    # name => size => +{ condition => name, %types/%structs }
                    if ( exists $type->{condition} ) {
                        my $seltype  = $type->{ $obj->{ $type->{condition} } };
                        my $rseltype = ref $seltype;
                        confess unless $rseltype eq 'ARRAY' || $rseltype eq '';

                        # name => size => +{ condition => name, %structs }
                        if ( $rseltype eq 'ARRAY' ) {
                            my ( $sub_obj, $parsed ) = $self->_parse( $value, $seltype );
                            confess unless $parsed == $size || $name eq 'Codec Specific Data';
                            $obj->{$name} = $sub_obj;
                        }

                        # name => size => +{ condition => name, %types }
                        elsif ( $rseltype eq '' ) {
                            $obj->{$name} = $self->_unpack( $value, $size, $seltype );
                        }
                    }

                    # name => size => +{ %values }
                    else {
                        $obj->{$name} = $type->{ $self->_unpack( $value, $size ) };
                    }
                }

                $pos += $size;
            }

            # name => []
            elsif ( $rsize eq 'ARRAY' ) {

                my ( $mode, $limit ) = ( $size->[0], $obj->{ ${$size->[1]} } );

                # name => [ mode => limit ] =>  []
                if ( $mode eq 'count' && $rtype eq 'ARRAY' ) {
                    foreach ( 1..$limit ) {
                        my ( $sub_obj, $parsed ) = $self->_parse( substr($data, $pos), $type );
                        push @{$obj->{$name}}, $sub_obj;
                        $pos += $parsed;
                    }
                }

                # name => [ mode => limit ] => +{}
                elsif ( $rtype eq 'HASH' ) {
                    confess if exists $type->{condition};
                    my ( $sub_obj, $parsed ) = $self->_parse( substr($data, $pos), $type, [ $mode => $limit ] );
                    $obj->{$name} = $sub_obj;
                    $pos += $parsed;
                }

                else {
                    confess;
                }
            }
        }# END foreach my $field (@$struct)
    }# END if ( $rstruct eq 'ARRAY' )

    # +{ %structures }
    elsif ( $rstruct eq 'HASH' ) {
        unless ( defined $limit ) {
            $limit = [ size => $ldata ];
        }
        my ( $mode, $limit ) = @$limit;
        while ( $mode eq 'count' ? $limit-- : $pos < $limit) {
            my $name = $self->_unpack( substr($data, $pos   , 16), 16 );
            my $size = $self->_unpack( substr($data, $pos+16,  8),  8 );
            my $sub_data = substr( $data, $pos, $size );
            my $sub_struct = $struct->{$name};

            unless ( defined $sub_struct ) {
                warn qq{Can't find the structure: $name (size: $size)};
                $pos += $size;
                next;
            }

            my ( $sub_obj, $parsed ) = $self->_parse( $sub_data, $sub_struct );
            confess unless $parsed == $size;

            if ( exists $obj->{$name} ) {
                if ( ref($obj->{$name}) eq 'ARRAY' ) {
                    push @{$obj->{$name}}, $sub_obj;
                }
                else {
                    $obj->{$name} = [ $obj->{$name}, $sub_obj ];
                }
            }
            else {
                $obj->{$name} = $sub_obj;
            }

            $pos += $size;
        }
    }


    ($obj, $pos);
}

sub _unpack {
    my ( $self, $bin, $bytes, $type ) = @_;

    if ( defined $type ) {
        if ( $type eq 'time' ) {
            Time::Piece
                ->localtime( $self->_unpack($bin, $bytes) / 1e7 - 11644473600 )
                ->strftime('%Y-%m-%d %H:%M:%S');
        }
        elsif ( $type eq 'wchar' ) {
            decode( 'utf16le', substr($bin, 0, length($bin)-1) );
        }
        elsif ( $type eq 'nchars' ) {
            $self->_unpack($bin, $bytes) * 2;
        }
    }
    else {
        my $bits = $bytes * 8;
        if    ( $bits ==   8 ) { # BYTE
            unpack( 'C', $bin );
        }
        elsif ( $bits ==  16 ) { # WORD
            unpack( 'v', $bin );
        }
        elsif ( $bits ==  32 ) { # DWORD
            unpack( 'V', $bin );
        }
        elsif ( $bits ==  64 ) { # QWORD
            my ( $l, $h ) = unpack( 'VV', $bin );
            $h*(2**32) + $l;
        }
        elsif ( $bits == 128 ) { # GUID
            my $guid = uc unpack( 'H*', pack( 'NnnNN', unpack( 'VvvNN', $bin ) ) );
            $guid =~ s/^(.{8})(.{4})(.{4})(.{4})/$1-$2-$3-$4-/;
            $self->spec->guid2name( $guid ) || $guid
        }
        else {
            $bin;
        }
    }
}

1;
