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
    my $err_info;
    local $SIG{__DIE__} = sub {
        die @_
            if ref $_[0] eq 'HASH' && $_[0]->{finished};
        $err_info = NanoA::DebugScreen::build(@_);
    };
    eval {
        NanoA::Dispatch->dispatch();
    };
    if ($@ && $err_info) {
        NanoA::DebugScreen::output($err_info);
    }
};

1;
