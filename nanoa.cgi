#! /usr/bin/perl

use strict;
use warnings;

if ($ENV{MOD_PERL}) {
    my $base_dir = $ENV{SCRIPT_FILENAME};
    $base_dir =~ s|/[^/]*$||;
    chdir $base_dir;
}

NanoA::Dispatch->dispatch({
    # prefix       => '.',
    # camelize     => 1,                  # camelize package names
    # prerun       => sub {},             # prerun hook
    # postrun      => sub {},             # postrun hook
    # mt_cache_dir => '/tmp/mt.cache'     # template cache dir
    # dbh          => DBI->connect(...),  # and your own properties
});

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
    my $module = NanoA::Mojo::Template::__load(
	$self->config,
	$self->config->{prefix} . "/$path");
    $module->run_as($self);
}

sub nanoa_uri {
    $ENV{SCRIPT_NAME};
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

package NanoA::Dispatch;

use strict;
use warnings;

sub dispatch {
    my ($klass, $config) = @_;
    
    $config->{prefix} ||= '.';
    $config->{mt_cache_dir} = $klass->default_cache_dir($config)
        unless exists $config->{mt_cache_dir};
    
    my $handler_path = $config->{prefix} . ($ENV{PATH_INFO} || '/');
    $handler_path =~ s{^\./}{};
    $handler_path =~ s{\.\.}{}g;
    $handler_path .= 'start'
	if $handler_path =~ m|^[^/]+/$|;
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
    NanoA::load_once("$path.pm")
        or return;
    my $module = $path;
    $module =~ s{/}{::}g;
    return $module;
}

sub load_mojo_template {
    my ($klass, $config, $path) = @_;
    $path =~ s{/+$}{};
    return
        unless -e "$path.mt";
    NanoA::Mojo::Template::__load($config, $path);
}

sub not_found {
    my ($klass, $config) = @_;
    $config->{not_found} || 'NanoA/NotFound';
}

sub default_cache_dir {
    my ($klass, $config) = @_;
    my $prefix = $config->{prefix};
    $prefix =~ s|/|::|g;
    "/tmp/nanoa.$prefix.$>.mt_cache";
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

sub __load {
    my ($config, $path) = @_;
    my $module = $path;
    $module =~ s{(^|/)\./}{$1}g;
    $module =~ s{/}{::}g;
    return $module
        if NanoA::loaded($path);
    if (__use_cache($config, $path)) {
        NanoA::load_once("$config->{mt_cache_dir}/$path.mtc", "$path.mt");
        return $module;
    }
    my $code = __compile($path, $module);
    local $@;
    eval $code;
    die $@ if $@;
    __update_cache($config, $path, $code)
        if $config->{mt_cache_dir};
    NanoA::loaded($path, 1);
    $module;
}

sub __compile {
    my ($path, $module) = @_;
    NanoA::require_once("Mojo/Template.pm");
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

sub __update_cache {
    my ($config, $path, $code) = @_;
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
    my ($config, $path) = @_;
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
