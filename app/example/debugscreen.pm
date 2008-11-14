package example::debugscreen;

use strict;
use warnings;

use base qw(NanoA);

sub run {
    &call_nonexisting_func;
}

1;

