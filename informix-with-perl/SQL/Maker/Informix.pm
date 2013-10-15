package SQL::Maker::Informix;
use strict;
use warnings;
use utf8;
use parent qw(SQL::Maker);

use SQL::Maker::Select::Informix;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    unless ($args{driver}) {
        Carp::confess("'driver' is required for creating new instance of $class");
    }
    my $driver = $args{driver};
    unless ( defined $args{quote_char} ) {
    $args{quote_char} =
          $driver eq 'Informix' ? q{}
        : $driver eq 'mysql'    ? q{'}
                                : q{"}
    }
    $args{select_class} =
          $driver eq 'Informix' ? 'SQL::Maker::Select::Informix'
        : $driver eq 'Oracle'   ? 'SQL::Maker::Select::Oracle'
                                : 'SQL::Maker';
    return bless {
        name_sep => '.',
        new_line => "\n",
        %args
    }, $class;
}

sub _quote { $_[1] }

1;
