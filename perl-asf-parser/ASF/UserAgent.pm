package ASF::UserAgent;
use strict;
use warnings;

use ASF::Parser;
use ASF::UserAgent::Response;

use FurlX::Coro::HTTP;
use Net::DNS::Lite;
use Cache::LRU;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    $Net::DNS::Lite::CACHE ||= Cache::LRU->new( size => 256 );
    my $ua = FurlX::Coro::HTTP->new(
        header_format => Furl::HTTP::HEADERS_AS_HASHREF(),
        inet_aton     => \&Net::DNS::Lite::inet_aton,
        agent         => 'NSPlayer/4.1.0.3938 (WebABC; StatusChecker)',
        timeout       => 4,
        max_redirects => 0,
        headers       => [
            'Accept'       => '*/*',
            'Content-Type' => 'application/x-mms-framed',
            'Pragma'       => 'no-cache',
        ],
        parser        => ASF::Parser->new(),
        cache         => undef,
        %args,
    );

    bless \$ua, $class;
}

sub parser { ${$_[0]}->{parser} }
sub cache  { ${$_[0]}->{cache} }

sub get {
    my ( $self, $host, $port ) = @_;

    unless ( $self->cache ) {
        return $self->_get( $host, $port );
    }

    my $res = $self->cache->get( $host, $port );
    unless ( $res ) {
        $res = $self->_get( $host, $port );
        $self->cache->set( $host, $port, $res );
    }

    $res;
}

sub _get {
    my ( $self, $host, $port ) = @_;

    my $limit = 1024 * 10; # 10k
    my %special_headers = ( 'content-length' => undef );
    my ( $minor_version, $code, $message, $headers ) = ();
    my $content = '';

    eval {
        ( $minor_version, $code, $message, $headers, $content ) = ${$self}->request(
            method          => 'GET',
            url             => sprintf('http://%s:%d', $host, $port),
            special_headers => \%special_headers,
            write_code      => sub {
                ( $code, $message, $headers, my $buf ) = @_;
                $content .= $buf;
                die length($content).' bytes received.'
                    if $self->parser->can_parse($content)
                    || ( $special_headers{'content-length'} || 0 ) > $limit
                    || length($content) > $limit;
            }
        );
    };
    #warn $@ if $@;

    my $object = +{};

    if ($code eq '200' &&
        $headers->{'content-type'} eq 'application/x-mms-framed' &&
        $self->parser->can_parse($content)) {

        $object = $self->parser->parse($content);
    }

    ASF::UserAgent::Response->new(
        $minor_version, $code, $message, $headers, $content, $object );
}

1;
