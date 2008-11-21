package NanoA::Plugin;

use strict;
use warnings;
use utf8;

sub import {
    my $pkg = caller;
    # plugins loading other plugins should call init_plugin explicitely
    return if $pkg =~ /^plugin::/;
    shift->init_plugin($pkg);
}

# plugins willing to install hooks should overide this method
sub init_plugin {
    my ($klass, $controller) = @_;
}

1;
