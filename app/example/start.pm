package example::start;

use base qw/NanoA/;

use strict;
use warnings;

sub run {
    my $app = shift;
    $app->render('example/template/start');
}

1;
