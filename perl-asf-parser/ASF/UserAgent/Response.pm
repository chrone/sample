package ASF::UserAgent::Response;
use strict;
use warnings;
use utf8;

use Time::Piece::HTTP ();

sub new {
    my ( $class, $minor_version, $code, $message, $headers, $content, $object ) = @_;

    bless +{
        code    => $code,
        message => $message,
        headers => $headers,
        content => $content,
        object  => $object,
        _lm     => time,
    }, $class;
}

sub code          { shift->{code} }
sub headers       { shift->{headers} }
sub content       { shift->{content} }
sub object        { shift->{object} }
sub last_modified { shift->{_lm} }
sub message {
    my $self = shift;
    my $message = $self->{message};
    $message =~ m{Cannot resolve host name} ? 'Cannot resolve hostname' :
    $message =~ m{Connection refused}       ? 'Connection refused'      :
    $message =~ m{timeout}                  ? 'Timeout'                 :
    $message =~ m{^(.+) at .+ line \d+[.]$} ? $1
                                            : $message
                                            ;
}
sub message_for_user {
    my $self = shift;
    my $message = $self->{message};
    $self->is_avail         ? 'OK'      :
    $self->is_busy          ? 'Busy'    :
    $message =~ m{timeout}i ? 'Timeout'
                            : 'Error'
                            ;
}

sub header     { $_[0]->code ne '500' ? $_[0]->headers->{$_[1]} : undef }
sub is_stream  { $_[0]->code ne '500' && $_[0]->header('content-type') eq 'application/x-mms-framed' }
sub is_avail   { $_[0]->code eq '200' && $_[0]->is_stream }
sub is_busy    { $_[0]->code eq '503' }
sub is_success { $_[0]->is_avail || $_[0]->is_busy }

sub coninfo {
    my $self = shift;
    my $code = $self->code;

    unless ($self->{coninfo}) {
        $self->{coninfo} = +{
            current => undef,
            max     => undef,
            reserve => undef,
        };
        return unless $self->is_success;
        return unless defined $self->header('pragma');

        my @pragmas = ref($self->header('pragma')) eq 'ARRAY'
            ? @{ $self->header('pragma') }
            :  ( $self->header('pragma') );

        foreach my $pragma (@pragmas) {
            if ($pragma =~ m{^coninfo=(\d+)/(\d+)(?:[+](\d+))?$}) {
                my ($current, $max, $reserve) = ($1, $2, $3);
                $self->{coninfo} = +{
                    current => $current,
                    max     => $max,
                    reserve => $reserve,
                }
            }
        }
    }

    wantarray ? %{$self->{coninfo}} : $self->{coninfo};
}

1;
