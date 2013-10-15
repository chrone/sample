package Proj::DB::Informix;
use strict;
use warnings;

use DBIx::Handler;
use SQL::Maker::Informix;

$Proj::DB::Informix::VERSION = '0.01';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    Carp::confess('database name required.') unless $args{database};

    # data source values
    $args{server}   //= $ENV{INFORMIXSERVER} // '<censored>';
    $args{username} //= $args{user}          // '<censored>';
    $args{password} //= $args{pass}          // '<censored>';
    $args{dsn}      //= sprintf('dbi:Informix:%s@%s', $args{database}, $args{server});

    # transaction settings
    $args{autocommit} = 1 unless defined($args{autocommit});

    # chop blanks of char
    $args{chopblanks} = 1 unless defined($args{chopblanks});

    $args{isolation} =
        ! $args{isolation}          ? 'DIRTY READ'  # default
        : $args{isolation} eq 'dr'  ? 'DIRTY READ'
        : $args{isolation} eq 'cr'  ? 'COMMITTED READ'
        : $args{isolation} eq 'lc'  ? 'COMMITTED READ LAST COMMITTED'
        : $args{isolation} eq 'cs'  ? 'CURSOR STABILITY'
        : $args{isolation} eq 'rr'  ? 'REPEATABLE READ'
        : $args{isolation} eq 'dru' ? 'DIRTY READ RETAIN UPDATE LOCKS'
        : $args{isolation} eq 'cru' ? 'COMMITTED READ RETAIN UPDATE LOCKS'
        : $args{isolation} eq 'lcu' ? 'COMMITTED READ LAST COMMITTED RETAIN UPDATE LOCKS'
        : $args{isolation} eq 'csu' ? 'CURSOR STABILITY RETAIN UPDATE LOCKS'
                                    : $args{isolation};

    $args{lockmode} =
        ! $args{lockmode}     ? 'WAIT 5'    # default
        : $args{lockmode} < 1 ? 'NOT WAIT'
                              : sprintf('WAIT %d', $args{lockmode});
    my @on_connect_do = (
        'SET ISOLATION TO '.$args{isolation},
        'SET LOCK MODE TO '.$args{lockmode},
        @{$args{on_connect_do} || []},
    );

    # connection environments for informix
    $ENV{DB_LOCALE}     = $args{db_locale}     // $ENV{DB_LOCALE}     // 'ja_JP.utf8';
    $ENV{CLIENT_LOCALE} = $args{client_locale} // $ENV{CLIENT_LOCALE} // 'en_US.utf8';
    $ENV{DBDATE}        = $args{dbdate}        // $ENV{DBDATE}        // 'Y4MD*';
    $ENV{PSORT_NPROCS}  = $args{psort_nprocs}  // $ENV{PSORT_NPROCS};
    $ENV{PDQPRIORITY}   = $args{pdqpriority}   // $ENV{PDQPRIORITY};

    $ENV{OPTOFC}                  = 0; # 1 -> sagfault
    $ENV{OPTMSG}                  = 1;
    $ENV{FET_BUF_SIZE}            = 32767;
    $ENV{IFX_NETBUF_SIZE}         = 8192;
    $ENV{IFX_NETBUF_PVTPOOL_SIZE} = 8192;

    delete $ENV{DB_LOCALE}               unless $ENV{DB_LOCALE};
    delete $ENV{CLIENT_LOCALE}           unless $ENV{CLIENT_LOCALE};
    delete $ENV{DBDATE}                  unless $ENV{DBDATE};
    delete $ENV{PSORT_NPROCS}            unless $ENV{PSORT_NPROCS};
    delete $ENV{PDQPRIORITY}             unless $ENV{PDQPRIORITY};

    # connect
    my $conn = DBIx::Handler->new(
        $args{dsn}, $args{username}, $args{password},
        {
            RootClass => 'DBIx::Simple::Inject',
            AutoCommit => $args{autocommit},
            ChopBlanks => $args{chopblanks},
            private_dbixsimple => {
                abstract => sub {
                    my $dbh = shift;
                    SQL::Maker::Informix->new(
                        driver => $dbh->{Driver}->{Name},
                        quote_char => '',
                    );
                },
                keep_statements => 32,
            },
        },
        {
            on_connect_do => \@on_connect_do,
        }
    );

    $conn;
}

1;

__END__

=head1 NAME

Proj::DB::Informix - fork-safe, easy-transaction handling, easy-to-use OO interface and transparent statement-handle cache. with DBD::Informix support.

=head1 SYNOPSIS

    my $conn = Proj::DB::Informix->new(
        server       => $informixserver,
        database     => $database,
        isolation    => 'lc', # lc: COMMITTED READ LAST COMMITTED
        pdqpriority  => 2,
        psort_nprocs => 4,
    );

    # begin transaction
    $txn_guard = $conn->dbh->txn_scope;

    # select, insert, delete, update
    $dbh = $conn->dbh;
    $result = $dbh->select($table, \@fields, \%where, \%opt);
    $result = $dbh->insert($table, \%values);
    $result = $dbh->delete($table, \%values);
    $result = $dbh->update($table, \%set, \%where);
    $result = $dbh->update($table, \@set, \%where);
    $result = $dbh->query($sql, @bind);

    # fetch
    @columns = $result->columns;
    $row = $result->fetch;

    @row = $result->list;      @rows = $result->flat;
    $row = $result->array;     @rows = $result->arrays;
    $row = $result->hash;      @rows = $result->hashes;
    @row = $result->kv_list;   @rows = $result->kv_flat;
    $row = $result->kv_array;  @rows = $result->kv_arrays;
    $obj = $result->object;    @objs = $result->objects;

    %map = $result->map_arrays($column_number);
    %map = $result->map_hashes($column_name);

    %map = $result->map;

    $rows = $result->rows;
    $dump = $result->text;

    $result->finish;

    # commit/rollback
    $txn_guard->commit;
    $txn_guard->rollback;

    # query trace
    $conn->trace_query(1);

    # using query builder
    $query_builder = $conn->abstract;
    ($sql, @bind) = $query_builder->select($table, \@fields, \%where, \%opt);

    # dynamic SQL generator
    $query = $query_builder->new_select;
    $query->add_from($table)
          ->add_where(%where)
          ->add_select($column);

    $sql = $query->as_sql;
    @bind = $query->bind;

    $result = $conn->dbh->query($sql, @bind);

=head1 AUTHOR

Yuki Irie <censored>

=head1 SEE ALSO

L<DBIx::Handler>, L<DBIx::Simple>, L<SQL::Maker>

=cut
