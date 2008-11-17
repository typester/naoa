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
        die $_[0]
            if ref $_[0] eq 'HASH' && $_[0]->{finished};
        NanoA::DebugScreen::build(@_);
    };
    eval {
        NanoA::Dispatch->dispatch();
    };
    if ($@ && ref $@ eq 'HASH' && $@->{finished}) {
        # just ignore
    }
};

1;
