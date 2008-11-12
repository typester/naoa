package example::user;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    'You are ' . h($self->query->param('id') || 'nanashi');
}

1;
