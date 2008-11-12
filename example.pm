package example;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    return << 'EOT';
<a href="example/user?id=kazuho">kazuho</a>
<a href="example/mojo?user=hoge">hoge</a>
EOT
    ;
}

1;
