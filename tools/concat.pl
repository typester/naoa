#! /usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $no_use = '';
GetOptions(
    'no-use=s' => \$no_use,
) or exit 1;
$no_use = { map { +($_ => 1) } split /\s*,\s*/, $no_use };


print "#!$^X\n";

my @files = @ARGV;
$no_use->{$_} = 1
    for map { my $n = $_; $n =~ s/\.pm$//; $n =~ s|/|::|g; $n } @files;

foreach my $file (@files) {
    open my $fh, '<', $file
        or die "open($file):$!";
    while (<$fh>) {
        last if /^(__END__|"ENDOFMODULE";)$/;
        if (/^use\s+([^ ]+);$/) {
            next if $no_use->{$1};
        }
        print;
    }
    close $fh;
}
print "1;\n";

