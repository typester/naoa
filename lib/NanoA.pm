package NanoA;

use strict;
use warnings;

sub new {
    my ($klass, $config, $q) = @_;
    bless {
        config  => $config,
        query   => $q,
        headers => {
            -type    => 'text/html',
            -charset => 'utf-8',
        },
    }, $klass;
}

sub prerun {
    my $self = shift;
    if (my $h = $self->config->{prerun}) {
        $h->($self);
    }
}

sub postrun {
    my ($self, $bodyref) = @_;
    if (my $h = $self->config->{postrun}) {
        $h->($self, $bodyref);
    }
}

sub query {
    my $self = shift;
    $self->{query} = shift
        if @_;
    $self->{query};
}

sub header_add {
    my ($self, %args) = @_;
    $self->{headers}->{$_} = $args{$_}
        for keys %args;
}

sub headers {
    my $self = shift;
    $self->{headers};
}

sub redirect {
    my ($self, $uri) = @_;
    $self->header_add(
        -status   => 302,
        -location => $uri,
    );
}

sub config {
    my $self = shift;
    return $self->{config}->{$_[0]}
        if @_ == 1;
    my %args = @_;
    $self->{config}->{$_} = $args{$_}
        for keys %args;
    $self->{config};
}

package NanoA::Dispatch;

use strict;
use warnings;

sub dispatch {
    my ($klass, $opts) = @_;
    
    my $q = $klass->build_query($opts);
    
    my $handler_path = $opts->{prefix} . ($q->path_info || '/');
    $handler_path =~ s{\.\.}{}g;
    
    my $handler_klass = $klass->load_handler($opts, $handler_path)
        || $klass->load_handler($opts, $klass->not_found);
    my $handler = $handler_klass->new($opts, $q);
    
    $handler->prerun();
    my $body = $handler->run();
    $handler->postrun(\$body);
    
    print $q->header(%{$handler->headers}), $body;
}

sub build_query {
    my ($klass, $opts) = @_;
    my $cgi_klass = $opts->{cgi_klass} || 'CGI::Simple';
    my $cgi_path = $cgi_klass;
    $cgi_path =~ s{::}{/}g;
    require "$cgi_path.pm";
    $cgi_klass->new;
}

sub load_handler {
    my ($klass, $opts, $path) = @_;
    my $handler_klass;
    
    foreach my $loader (
        ($opts->{loaders} ? @{$opts->{loaders}} : ()),
        \&load_pm,
    ) {
        $handler_klass = $loader->($klass, $opts, $path)
            and last;
    }
    
    $handler_klass;
}

sub load_pm {
    my ($klass, $opts, $path) = @_;
    $path =~ s{/+$}{};
    $path = camelize($path)
        if $opts->{camelize};
    local $@;
    eval {
        # should have a different invocation model for mod_perl and fastcgi
        require "$path.pm";
    };
    unless ($@) {
        my $module = $path;
        $module =~ s{/}{::}g;
        return $module;
    }
    return
        if $@ =~ /^Can't locate /;
    die $@;
}

sub not_found {
    my ($klass, $opts) = @_;
    $opts->{not_found} || 'NanoA/NotFound';
}

sub camelize {
    # copied from String::CamelCase by YAMANSHINA Hio
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

1;
