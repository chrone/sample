package ASF::UserAgent::Cache::DB;
use strict;
use warnings;
{
    use ASF::UserAgent::Response;

    sub new {
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;

        die 'argument "conn" required.' unless $args{conn};

        bless {
            conn   => delete($args{conn}),
            expire => 60,
            %args,
        }, $class;
    }

    sub expire     { shift->{expire} }
    sub conn       { shift->{conn} }
    sub dbh        { shift->conn->dbh }
    sub new_select { shift->dbh->abstract->new_select }

    sub set {
        my ($self, $host, $port, $res) = @_;

        my $address_id = $self->find_or_create( address => {
            host => $host,
            port => $port,
        });

        my $status_id = $self->find_or_create( status => {
            code    => $res->code,
            message => $res->message,
        });

        my $content_type_id;
        if ($res->header('content-type')) {
            $content_type_id = $self->find_or_create( content_type => {
                content_type => $res->header('content-type'),
            });
        }

        my $x_server_id;
        if ($res->header('x-server')) {
            $x_server_id = $self->find_or_create( x_server => {
                x_server => $res->header('x-server'),
            });
        }

        my $stream_id;
        if ($res->is_avail) {
            my $obj = $res->object;
            $stream_id = $self->find_or_create( stream => {
                file_id          => $obj->file_id_by_binary,
                creation_date    => $obj->creation_date,
                preroll          => $obj->preroll,
                video_width      => $obj->video_width,
                video_height     => $obj->video_height,
                video_bitrate    => $obj->video_bitrate,
                video_framerate  => $obj->video_framerate,
                audio_bitrate    => $obj->audio_bitrate,
                audio_samplerate => $obj->audio_samplerate,
                audio_channels   => $obj->audio_channels,
            }, [qw(file_id creation_date)]);
        }

        my $coninfo = $res->coninfo;
        $self->dbh->insert( scan_log => {
            address_id      => $address_id,
            status_id       => $status_id,
            content_type_id => $content_type_id,
            x_server_id     => $x_server_id,
            conn_current    => $coninfo->{current},
            conn_max        => $coninfo->{max},
            conn_reserve    => $coninfo->{reserve},
            stream_id       => $stream_id,
        });
    }

    sub get {
        my ($self, $host, $port) = @_;

        my $st = $self->new_select
            ->add_join([ scan_log => 'l' ] => {
                type      => 'inner',
                table     => 'address',
                alias     => 'a',
                condition => 'l.address_id = a.id',
            })
            ->add_join([ scan_log => 'l' ] => {
                type      => 'inner',
                table     => 'status',
                alias     => 'sta',
                condition => 'l.status_id = sta.id',
            })
            ->add_join([ scan_log => 'l' ] => {
                type      => 'left',
                table     => 'content_type',
                alias     => 'ct',
                condition => 'l.content_type_id = ct.id',
            })
            ->add_join([ scan_log => 'l' ] => {
                type      => 'left',
                table     => 'x_server',
                alias     => 'xs',
                condition => 'l.x_server_id = xs.id',
            })
            ->add_join([ scan_log => 'l' ] => {
                type      => 'left',
                table     => 'stream',
                alias     => 'str',
                condition => 'l.stream_id = str.id',
            })
            ->add_where( 'a.host' => $host )
            ->add_where( 'a.port' => $port )
            ->add_where( 'l.inserted_at' => \['>= now() - interval ? second', $self->expire()] )
            ->add_order_by( 'l.inserted_at' => 'desc' )
            ->limit( 1 )

            ->add_select('a.host')
            ->add_select('a.port')
            ->add_select('sta.code')
            ->add_select('sta.message')
            ->add_select('ct.content_type')
            ->add_select('xs.x_server')
            ->add_select('l.conn_current')
            ->add_select('l.conn_max')
            ->add_select('l.conn_reserve')
            ->add_select('str.preroll')
            ->add_select('str.audio_samplerate')
            ->add_select('str.audio_channels')
            ->add_select('str.audio_bitrate')
            ->add_select('str.video_width')
            ->add_select('str.video_height')
            ->add_select('str.video_bitrate')
            ->add_select('str.video_framerate')
            ;

        my $db_res = $self->dbh->query( $st->as_sql, $st->bind )->hash;
        return unless $db_res;

        my $object = ASF::UserAgent::Cache::DB::Response->new( $db_res );
        my $res = ASF::UserAgent::Response->new(
            undef,
            $db_res->{code},
            $db_res->{message},
            +{
                'content-type' => $db_res->{content_type},
                'x-server'     => $db_res->{x_server},
            },
            undef,
            $object,
        );
        $res->{coninfo} = +{
            current => $db_res->{conn_current},
            max     => $db_res->{conn_max},
            reserve => $db_res->{conn_reserve},
        };
        $res;
    }

    sub find_or_create {
        my ($self, $table, $data, $cond_col) = @_;

        $cond_col ||= [ keys %$data ];
        my %condition;
        @condition{@$cond_col} = @{$data}{@$cond_col};

        my ($id) = $self->dbh->select( $table => ['id'], \%condition )->flat;
        unless ($id) {
            $self->dbh->insert( $table => $data );
            $id = $self->dbh->{mysql_insertid};
        }

        $id;
    }
}

package ASF::UserAgent::Cache::DB::Response;
{
    sub new {
        my $class = shift;
        my %args = @_ == 1 ? %{$_[0]} : @_;
        bless +{
            map { $_ => $args{$_} } qw(
                preroll
                audio_samplerate
                audio_channels
                audio_bitrate
                video_width
                video_height
                video_bitrate
                video_framerate
            )
        }, $class;
    }

    sub preroll          { shift->{preroll} }

    sub audio_samplerate { shift->{audio_samplerate} }
    sub audio_channels   { shift->{audio_channels} }
    sub audio_bitrate    { shift->{audio_bitrate} }
    sub video_width      { shift->{video_width} }
    sub video_height     { shift->{video_height} }
    sub video_bitrate    { shift->{video_bitrate} }
    sub video_framerate  { shift->{video_framerate} }
}

1;
