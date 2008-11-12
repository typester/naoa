package example::start;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    return << 'EOT';
<a href="./user?id=kazuho">kazuho</a>
<a href="./mojo?user=hoge">hoge</a>
EOT
    ;
}

1;
