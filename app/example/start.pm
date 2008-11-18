package example::start;

use NanoA;
use base qw/NanoA/;

sub run {
    my $app = shift;
    $app->render('example/template/start');
}

1;
