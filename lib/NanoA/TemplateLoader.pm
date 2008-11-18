package NanoA::TemplateLoader;

use strict;
use warnings;

use NanoA;
use base qw(NanoA);

sub __load {
    my ($config, $module, $path) = @_;
    if (__use_cache($config, $path)) {
        NanoA::load_once($config->mt_cache_dir . "/$path.c", $path);
        return $module;
    }
    my $code = __compile($path, $module);
    local $@;
    eval $code;
    die $@ if $@;
    __update_cache($config, $path, $code)
        if $config->mt_cache_dir;
    NanoA::loaded($path, 1);
}

sub __compile {
    my ($path, $module) = @_;
    NanoA::require_once('MENTA/Template.pm');
    my $t = MENTA::Template->new;
    $t->parse(NanoA::read_file($path));
    $t->build();
    my $code = $t->code();
    $code = << "EOT";
package $module;
use NanoA;
use NanoA::TemplateLoader;
use base qw(NanoA::TemplateLoader);
sub run {
    my (\$app, \$c) = \@_;
    $code->();
}
sub run_as {
    my (\$klass, \$app, \$c) = \@_;
    run(\$app, \$c);
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
    $cache_path .= '.c';
    open my $fh, '>:utf8', $cache_path
        or die "failed to create cache file $cache_path";
    print $fh $code;
    close $fh;
}

sub __use_cache {
    my ($config, $path) = @_;
    return unless $config->mt_cache_dir;
    my @orig = stat $path
        or return;
    my @cached = stat $config->mt_cache_dir . "/$path.c"
        or return;
    return $orig[9] < $cached[9];
}

"ENDOFMODULE";

