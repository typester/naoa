print "#!$^X\n";
foreach my $file (@ARGV) {
    open my $fh, '<', $file
        or die "open($file):$!";
    while (<$fh>) {
        last if /^(__END__|"ENDOFMODULE";)$/;
        next if /^\s*$/;
        next if /^use\s+(strict|warnings);$/;
        print
    }
    close $fh;
}
print "1;\n";

