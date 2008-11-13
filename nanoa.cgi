#! /usr/bin/perl

use strict;
use warnings;
use utf8;

if ($ENV{MOD_PERL}) {
    my $base_dir = $ENV{SCRIPT_FILENAME};
    $base_dir =~ s|/[^/]*$||;
    chdir $base_dir;
}
unshift @INC, 'extlib';

NanoA::Dispatch->dispatch();

package NanoA;

use strict;
use warnings;

my %REQUIRED;
my %LOADED;

BEGIN {
    %REQUIRED = ();
    %LOADED = ();
};

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
        require_once("$cgi_path.pm");
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

sub render {
    my ($self, $path) = @_;
    my $module = NanoA::TemplateLoader::__load($self->config, $path);
    $module->run_as($self);
}

sub escape_html {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    return $str;
}

sub nanoa_uri {
    $ENV{SCRIPT_NAME} || '.';
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
    my $ct = delete $headers->{-type};
    if ($ct =~ /;\s*charset=/) {
        delete $headers->{-charset};
    } else {
        $ct .= "; charset=" . delete $headers->{-charset};
    }
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

sub require_once {
    my $path = shift;
    return if $REQUIRED{$path};
    require $path;
    $REQUIRED{$path} = 1;
}

sub load_once {
    my ($path, $mark_path) = @_;
    $mark_path ||= $path;
    return if $LOADED{$mark_path};
    local $@;
    if (do "$path") {
        $LOADED{mark_path} = 1;
        return 1;
    }
    die $@
        if $@;
    undef;
}

sub loaded {
    my $path = shift;
    $LOADED{$path} = shift
        if @_;
    $LOADED{$path};
}

sub __insert_methods {
    my $module = shift;
    no strict 'refs';
    print "Adding functions to $module\n";
    *{"$module\::$_"} = \&{$_}
        for qw(h);
}

package NanoA::config;

use strict;
use warnings;

sub new {
    my ($klass, $opts) = @_;
    bless {
        prerun       => undef,
        postrun      => undef,
        camelize     => undef,
        loaders      => [
            \&NanoA::Dispatch::load_mojo_template,
            \&NanoA::Dispatch::load_pm,
        ],
        not_found    => 'NanoA/NotFound',
        mt_cache_dir => "/tmp/nanoa.$>.mt_cache",
        $opts ? %$opts : (),
    }, $klass;
}

sub prerun {
    my $self = shift;
    $self->{prerun};
}

sub postrun {
    my $self = shift;
    $self->{postrun};
}

sub camelize {
    my $self = shift;
    $self->{camelize};
}

sub loaders {
    my $self = shift;
    $self->{loaders};
}

sub not_found {
    my $self = shift;
    $self->{not_found};
}

sub mt_cache_dir {
    my $self = shift;
    $self->{mt_cache_dir};
}

package NanoA::Dispatch;

use strict;
use warnings;

sub dispatch {
    my $klass = shift;
    
    my $handler_path = substr($ENV{PATH_INFO} || '/', 1);
    $handler_path =~ s{\.\.}{}g;
    $handler_path .= 'start'
        if $handler_path =~ m|^[^/]+/$|;
    
    # TODO: should load config here
    my $config = $klass->load_config($handler_path);
    
    $handler_path = camelize($handler_path)
        if $config->camelize;
    
    my $handler_klass = $klass->load_handler($config, $handler_path)
        || $klass->load_handler($config, $config->not_found);
    my $handler = $handler_klass->new($config);
    
    $handler->prerun();
    my $body = $handler->run();
    $handler->postrun(\$body);
    
    $handler->print_header();
    print $body;
}

sub load_config {
    my ($klass, $handler_path) = @_;
    if ($handler_path =~ m|^(.*?)/|) {
        my $config_path = "$1/config";
        if (NanoA::load_once("$config_path.pm")) {
            my $module = $config_path;
            $module =~ s{/}{::}g;
            return $module->new();
        }
    }
    return "NanoA::config"->new();
}

sub load_handler {
    my ($klass, $config, $path) = @_;
    my $handler_klass;
    
    foreach my $loader (@{$config->loaders}) {
        $handler_klass = $loader->($klass, $config, $path)
            and last;
    }
    
    $handler_klass;
}

sub load_pm {
    my ($klass, $config, $path) = @_;
    $path =~ s{/+$}{};
    local $@;
    NanoA::load_once("$path.pm")
        or return;
    my $module = $path;
    $module =~ s{/}{::}g;
    NanoA::__insert_methods($module);
    return $module;
}

sub load_mojo_template {
    my ($klass, $config, $path) = @_;
    $path =~ s{/+$}{};
    return
        unless -e "$path.mt";
    NanoA::TemplateLoader::__load($config, $path);
}

sub camelize {
    # originally copied from String::CamelCase by YAMANSHINA Hio
    my $s = shift;
    lcfirst join(
        '',
        map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s),
    );
}

package NanoA::TemplateLoader;

use strict;
use warnings;

use base qw(NanoA);

sub __load {
    my ($config, $path) = @_;
    my $module = $path;
    $module =~ s{(^|/)\./}{$1}g;
    $module =~ s{/}{::}g;
    return $module
        if NanoA::loaded($path);
    if (__use_cache($config, $path)) {
        NanoA::load_once($config->mt_cache_dir . "/$path.mtc", "$path.mt");
        return $module;
    }
    my $code = __compile($path, $module);
    local $@;
    eval $code;
    die $@ if $@;
    __update_cache($config, $path, $code)
        if $config->mt_cache_dir;
    NanoA::loaded($path, 1);
    $module;
}

sub __compile {
    my ($path, $module) = @_;
    NanoA::require_once("MENTA/Template.pm");
    my $t = MENTA::Template->new;
    $t->parse(__read_file("$path.mt"));
    $t->build();
    my $code = $t->code();
    $code = << "EOT";
package $module;
use base qw(NanoA::TemplateLoader);
BEGIN {
    no strict 'refs';
    *escape_html = \\&{'NanoA::escape_html'};
};
sub run {
    my \$app = shift;
    $code->();
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

sub __update_cache {
    my ($config, $path, $code) = @_;
    my $cache_path = $config->mt_cache_dir;
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
    my ($config, $path) = @_;
    return unless $config->mt_cache_dir;
    my @orig = stat "$path.mt"
        or return;
    my @cached = stat $config->mt_cache_dir . "/$path.mtc"
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
