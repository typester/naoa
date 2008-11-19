print "#!$^X\n";
foreach my $file (@ARGV) {
    local @ARGV = ($file);
    while (<>) {
        last if /^(__END__|"ENDOFMODULE";)$/;
        next if /^\s*$/;
        print
    }
}
print "1;\n";

