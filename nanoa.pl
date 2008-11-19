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
    my $err_info;
    local $SIG{__DIE__} = sub {
        my ($msg) = @_;
        $err_info = NanoA::DebugScreen::build($msg)
            unless ref($msg) eq 'HASH' && $msg->{finished};
        die;
    };
    local $@;
    eval {
        NanoA::Dispatch->dispatch();
        undef $err_info;
    };
    NanoA::DebugScreen::output($err_info)
        if $err_info;
};

1;
