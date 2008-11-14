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
    local $@;
    local $SIG{__DIE__} = sub {
        NanoA::DebugScreen::build(@_);
    };
    eval {
        NanoA::Dispatch->dispatch();
    };
    if ($@) {
        if (ref $@ eq 'HASH') {
            NanoA::DebugScreen::output($@);
        } else {
            die $@;
        }
    }
};

