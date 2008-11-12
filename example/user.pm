package example::user;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    my $name = $self->query->param('id');
    $self->header_add(
        -type => 'text/plain',
    );
    return << "EOT";
You are $name
EOT
    ;
}

1;
