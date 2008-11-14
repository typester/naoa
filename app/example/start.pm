package example::start;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    $self->render('example/template/start');
}

1;
