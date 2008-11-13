package example::user;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    'You are ' . escape_html($self->query->param('id') || 'nanashi');
}

1;
