use strict;
use warnings;
use utf8;

BEGIN {
    unshift @INC, 'extlib';
};

if ($ENV{MOD_PERL}) {
    my $base_dir = $ENV{SCRIPT_FILENAME};
    $base_dir =~ s|/[^/]*$||;
    chdir $base_dir;
}

CGI::ExceptionManager->run(
    callback   => \&NanoA::Dispatch::dispatch,
    powered_by => 'NanoA',
);

1;
