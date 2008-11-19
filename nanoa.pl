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
        if (ref($_[0]) eq 'HASH' && $_[0]->{finished}) {
            undef $err_info;
        } else {
            $err_info = NanoA::DebugScreen->new(
                waf_name => 'NanoA',
            );
        }
        die;
    };
    local $@;
    eval {
        NanoA::Dispatch->dispatch();
        undef $err_info;
    };
    $err_info->output
        if $err_info;
};

1;
