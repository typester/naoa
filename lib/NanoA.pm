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
    $handler_path = camelize($handler_path)
        if $opts->{camelize};
    
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
        \&load_mojo_template,
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

sub load_mojo_template {
    my ($klass, $opts, $path) = @_;
    $path =~ s{/+$}{};
    return
        unless -e "$path.mt";
    NanoA::Mojo::Template->__load($path);
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

package NanoA::Mojo::Template;

use strict;
use warnings;

use base qw(NanoA);

sub include {
    my ($app, $path) = @_;
    my $module = $app->__load($app->config->{prefix} . "/$path");
    $module->__run_as($app);
}

sub __load {
    my ($self, $path) = @_;
    my ($module, $code) = $self->__compile($path);
    local $@;
    eval $code;
    die $@ if $@;
    $module;
}

sub __compile {
    my ($self, $path) = @_;
    my $module = $path;
    $module =~ s{/}{::};
    __load_once("Mojo/Template.pm");
    my $mt = Mojo::Template->new;
    $mt->parse(__read_file("$path.mt"));
    $mt->build();
    my $code = $mt->code();
    $code = << "EOT";
package $module;
use base qw(NanoA::Mojo::Template);
sub run {
    my \$app = shift;
    my \$code = $code;
    \$code->();
}
sub __run_as {
    my (\$klass, \$app) = \@_;
    run(\$app);
}
1;
EOT
;
    ($module, $code);
}

my %LOADED;

sub __load_once {
    my $path = shift;
    return if $LOADED{$path};
    require "$path";
}

sub __read_file {
    my $fname = shift;
    open my $fh, '<', $fname or die "cannot read $fname:$!";
    my $s = do { local $/; join '', <$fh> };
    close $fh;
    $s;
}

1;
