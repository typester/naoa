print "#!$^X\n";
foreach my $file (@ARGV) {
    local @ARGV = ($file);
    while (<>) {
        last if /^(__END__|"ENDOFMODULE";)$/;
        next if /^\s*$/;
        next if /^use\s+(strict|warnings);$/;
        print
    }
}
print "1;\n";

