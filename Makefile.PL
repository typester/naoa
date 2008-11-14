# NOTES:
#   このファイル、およびlibはあくまで開発者向けのもので、ユーザーには
#       nanoa.cgi
#       system/not_found.mt
#       system/app_list.mt
#       system/header.mt
#       system/footer.mt
#   の4ファイルのみを提供する。
#
#   nanoa.cgiはmake nanoaで作成される

use strict;
use inc::Module::Install;
use File::Find::Rule; # ここで使うだけだから許して！
use File::Spec;

name('NanoA');
all_from('lib/NanoA.pm');

# requires には Perl 5.8にデフォルトでインストールされているもの以外は
# 使ってはいけません

# ここでnanoaルールを定義
my @copy_extlib = qw(
    extlib/CGI/Simple.pm
    extlib/CGI/Simple/Cookie.pm
    extlib/CGI/Simple/Util.pm
    extlib/MENTA/Template.pm
);

my $appfiles = join(
    ' ',
    File::Find::Rule->file()->name('*.pm', '*.mt')->in('app'),
);

my $distdir = File::Spec->catfile('dist-cgi', version());
my $postamble = <<EOM;
NANOADIR = $distdir

EOM

$postamble .= <<'EOM';
nanoadir: 
	$(NOECHO)$(RM_RF) $(NANOADIR);
	$(NOECHO)$(MKPATH) $(NANOADIR);

nanoacgi: $(TO_INST_PM)
	$(NOECHO)$(FULLPERLRUN) -e ' \
		print "#!$$^X\n"; \
		foreach my $$file (@ARGV) { \
			local @ARGV = ($$file); \
			while (<>) { \
				last if /^(__END__|"ENDOFMODULE";)$$/; \
				next if /^\s*$$/; \
				print \
		 } \
		} \
		print "1;\n";\
	' $(TO_INST_PM) $(EXTLIBS) > $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(CHMOD) 755 $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(ECHO) "Generated $(NANOADIR)/nanoa.cgi"

nanoamanifest:
	$(NOECHO)$(FULLPERLRUN) tools/manifest.pl $(NANOADIR) > $(NANOADIR)/MANIFEST

nanoaapp:
EOM

$postamble .= <<"EOM";
	\$(NOECHO) tar cf - $appfiles | (cd \$(NANOADIR) && tar xf -)
EOM

$postamble .= <<'EOM';

nanoa: nanoadir nanoacgi nanoaextlib nanoaapp nanoamanifest
	$(NOECHO)$(NOOP)

nanoaextlib: 
	$(NOECHO)$(MKPATH) $(NANOADIR)/extlib/CGI/Simple
	$(NOECHO)$(MKPATH) $(NANOADIR)/extlib/MENTA
EOM

foreach my $file (@copy_extlib) {
    $postamble .= <<"EOM";
	\$(NOECHO)\$(CP) $file \$(NANOADIR)/$file
EOM
}

postamble($postamble);

WriteAll;
