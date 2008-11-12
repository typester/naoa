package MyApp;

use strict;
use warnings;

use base qw/NanoA/;

sub run {
    my $self = shift;
    return << 'EOT';
<a href="index.cgi/user?id=kazuho">kazuho</a>
<a href="index.cgi/mojo?user=hoge">hoge</a>
EOT
    ;
}

1;
