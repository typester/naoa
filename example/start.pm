package example::start;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    my $o = $self->render('example/template/start');
    $o;
}

1;
