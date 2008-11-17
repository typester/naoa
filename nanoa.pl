use strict;
use warnings;
use utf8;

if ($ENV{MOD_PERL}) {
    my $base_dir = $ENV{SCRIPT_FILENAME};
    $base_dir =~ s|/[^/]*$||;
    chdir $base_dir;
}
unshift @INC, 'extlib';

do {
    local $SIG{__DIE__} = sub {
        NanoA::DebugScreen::build(@_);
    };
    NanoA::Dispatch->dispatch();
};

1;
