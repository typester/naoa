package example::user;

use NanoA;
use base qw/NanoA/;

sub run {
    my $self = shift;
    'You are ' . escape_html($self->query->param('id') || 'nanashi');
}

1;
