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

my @systmpl = File::Find::Rule->file()->name('*.mt')->in('system');
my @examples = File::Find::Rule->file()->in('example');

my $postamble = <<'EOM';
NANOADIR = dist-cgi
NANOATMPLDIR = $(NANOADIR)/system
NANOAAPPDIR = $(NANOADIR)/app
NANOACGI = system/nanoa.cgi

nanoadir: 
	$(NOECHO)$(MKPATH) $(NANOADIR); \

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
	' $(NANOACGI) $(TO_INST_PM) $(EXTLIBS) > $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(CHMOD) 755 $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(ECHO) "Generated $(NANOADIR)/nanoa.cgi"

nanoaexample:
	$(NOECHO) $(MKPATH) $(NANOAAPPDIR)
	$(NOECHO) tar cf - example | (cd $(NANOAAPPDIR) && tar xf -)

nanoa: nanoadir nanoacgi nanoasystmpl nanoaextlib nanoaexample
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

$postamble .= <<'EOM';

nanoasystmpl:
	$(NOECHO) $(MKPATH) $(NANOATMPLDIR);
EOM

foreach my $file (@systmpl) {
	$postamble .= <<"EOM";
	\$(NOECHO) \$(CP) $file \$(NANOADIR)/$file
EOM
}

postamble($postamble);

WriteAll;