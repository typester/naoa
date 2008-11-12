package NanoA;

use strict;
use warnings;

sub new {
    my ($klass, $config) = @_;
    bless {
        config  => $config,
        query   => undef,
        headers => {
            -type    => 'text/html',
            -charset => 'utf8',
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
    unless ($self->{query}) {
        my $cgi_klass = $self->config('cgi_klass') || 'CGI::Simple';
        my $cgi_path = $cgi_klass;
        $cgi_path =~ s{::}{/}g;
        require "$cgi_path.pm";
        $self->{query} = $cgi_klass->new;
    }
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

sub print_header {
    my $self = shift;
    my $headers = $self->{headers};
    my $ct =
        delete($headers->{-type}) . "; charset=" . delete($headers->{-charset});
    print "Content-Type: $ct\n";
    foreach my $n (sort keys %$headers) {
        my $v = $headers->{$n};
        $n =~ s/^-//;
        $n =~ tr/_/-/;
        if (ref $v eq 'ARRAY') {
            foreach my $vv (@$v) {
                print "$n: $v\n";
            }
        } else {
            print "$n: $v\n";
        }
    }
    print "\n";
}
    
package NanoA::Dispatch;

use strict;
use warnings;

sub dispatch {
    my ($klass, $config) = @_;
    
    $config->{mt_cache_dir} = $klass->default_cache_dir($config)
        unless exists $config->{mt_cache_dir};
    
    my $handler_path = $config->{prefix} . ($ENV{PATH_INFO} || '/');
    $handler_path =~ s{\.\.}{}g;
    $handler_path = camelize($handler_path)
        if $config->{camelize};
    
    my $handler_klass = $klass->load_handler($config, $handler_path)
        || $klass->load_handler($config, $klass->not_found);
    my $handler = $handler_klass->new($config);
    
    $handler->prerun();
    my $body = $handler->run();
    $handler->postrun(\$body);
    
    $handler->print_header();
    print $body;
}

sub load_handler {
    my ($klass, $config, $path) = @_;
    my $handler_klass;
    
    foreach my $loader (
        ($config->{loaders} ? @{$config->{loaders}} : ()),
        \&load_mojo_template,
        \&load_pm,
    ) {
        $handler_klass = $loader->($klass, $config, $path)
            and last;
    }
    
    $handler_klass;
}

sub load_pm {
    my ($klass, $config, $path) = @_;
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
    my ($klass, $config, $path) = @_;
    $path =~ s{/+$}{};
    return
        unless -e "$path.mt";
    NanoA::Mojo::Template->__load($config, $path);
}

sub not_found {
    my ($klass, $config) = @_;
    $config->{not_found} || 'NanoA/NotFound';
}

sub default_cache_dir {
    my ($klass, $config) = @_;
    my $prefix = $config->{prefix};
    $prefix =~ s|/|::|g;
    "/tmp/$prefix.$>.mt_cache";
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

my %LOADED;

sub include {
    my ($app, $path) = @_;
    my $module = $app->__load($app->config, $app->config->{prefix} . "/$path");
    $module->run_as($app);
}

sub __load {
    my ($self, $config, $path) = @_;
    my $module = $path;
    $module =~ s{/}{::}g;
    return $module
        if $LOADED{$path};
    if ($self->__use_cache($config, $path)) {
        require "$config->{mt_cache_dir}/$path.mtc";
        $LOADED{$path} = 1;
        return $module;
    }
    my $code = $self->__compile($path, $module);
    local $@;
    eval $code;
    die $@ if $@;
    $self->__update_cache($config, $path, $code)
        if $config->{mt_cache_dir};
    $LOADED{$path} = 1;
    $module;
}

sub __compile {
    my ($self, $path, $module) = @_;
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
sub run_as {
    my (\$klass, \$app) = \@_;
    run(\$app);
}
1;
EOT
;
    $code;
}

sub __load_once {
    my $path = shift;
    return if $LOADED{$path};
    require "$path";
}

sub __update_cache {
    my ($self, $config, $path, $code) = @_;
    my $cache_path = $config->{mt_cache_dir};
    foreach my $p (split '/', $path) {
        mkdir $cache_path;
        $cache_path .= "/$p";
    }
    $cache_path .= '.mtc';
    open my $fh, '>', $cache_path
        or die "failed to create cache file $cache_path";
    print $fh $code;
    close $fh;
}

sub __use_cache {
    my ($self, $config, $path) = @_;
    return unless $config->{mt_cache_dir};
    my @orig = stat "$path.mt"
        or return;
    my @cached = stat "$config->{mt_cache_dir}/$path.mtc"
        or return;
    return $orig[9] < $cached[9];
}

sub __read_file {
    my $fname = shift;
    open my $fh, '<', $fname or die "cannot read $fname:$!";
    my $s = do { local $/; join '', <$fh> };
    close $fh;
    $s;
}

1;
