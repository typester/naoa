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
    my $app_name;
    my $module_name = "NanoA::Config";
    if ($handler_path =~ m|^(.*?)/|) {
        $app_name = $1;
        $module_name = "$app_name\::config"
            if NanoA::load_once("$app_name/config.pm");
    }
    return $module_name->new({
        app_name => $app_name,
    });
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

"ENDOFMODULE";