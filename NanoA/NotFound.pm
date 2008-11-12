package NanoA::NotFound;

use strict;
use warnings;

use base qw(NanoA);

sub run {
    my ($self, $q) = @_;
    
    $self->header_add(
        status => 404,
        type   => 'text/plain',
    );
    "not found";
}

1;
