package SQL::Maker::Select::Informix;
use strict;
use warnings;
use parent qw(SQL::Maker::Select);

sub as_sql_limit {
    return '';
}

sub as_sql {
    my $stmt        = shift;
    my $limit       = $stmt->{limit};
    my $offset      = $stmt->{offset};
    my $sql         = $stmt->SUPER::as_sql(@_);
    my $new_line    = $stmt->new_line;

    if (defined $limit) {
        if ($sql =~ m/\ASELECT (.*)\z/s) {
            $sql = $1;
        }
        if (defined $offset) {
            $sql = "SELECT SKIP $offset FIRST $limit\n$sql";
        } else {
            $sql = "SELECT FIRST $limit\n$sql";
        }
    }

    return $sql;
}

1;
