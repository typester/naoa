package example::debugscreen;

use NanoA;
use base qw(NanoA);

sub run {
    &call_nonexisting_func;
}

1;

