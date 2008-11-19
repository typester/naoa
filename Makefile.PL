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
my @extra_files = qw(
    .htaccess
    nanoa-conf.cgi
);

my $version = version();
my $distdir = File::Spec->catfile('dist-cgi', $version);
my $postamble = <<EOM;
NANOADIR = $distdir

EOM

$postamble .= <<'EOM';
nanoadir: 
	$(NOECHO)$(RM_RF) $(NANOADIR);
	$(NOECHO)$(MKPATH) $(NANOADIR);

nanoacgi: $(TO_INST_PM)
	$(NOECHO)$(FULLPERLRUN) tools/concat.pl $(TO_INST_PM) $(EXTLIBS) > $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(CHMOD) 755 $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(ECHO) "Generated $(NANOADIR)/nanoa.cgi"

nanoamanifest:
	$(NOECHO)$(FULLPERLRUN) tools/manifest.pl $(NANOADIR) > $(NANOADIR)/MANIFEST

nanoaapp:
	$(NOECHO)$(MKPATH) $(NANOADIR)/app
	(cd app && tar cf - --no-recursion `svn ls -R`) | (cd $(NANOADIR)/app && tar xf -)

nanoa-dist: nanoa
EOM

$postamble .= <<"EOM";
	\$(NOECHO)(cd \$(NANOADIR) && tar czf ../nanoa-$version.tar.gz .)
	tgz2cgi/tgz2cgi.pl --title='NanoA Installer' --end='<a href="./">Next step</a><script>window.setTimeout(function () { location = "./"; }, 5000)</script>' --check-files=.htaccess,nanoa.cgi,lib,extlib,var,app --nph < dist-cgi/nanoa-$version.tar.gz > dist-cgi/nph-nanoa-$version-installer.cgi
	\$(NOECHO)chmod 755 dist-cgi/nph-nanoa-$version-installer.cgi
EOM

$postamble .= <<'EOM';
	$(NOECHO)rm -r $(NANOADIR)


nanoa: nanoadir nanoacgi nanoaextlib nanoaapp nanoamanifest
	$(NOECHO)$(NOOP)

nanoaextlib: 
	$(NOECHO)$(MKPATH) $(NANOADIR)/extlib
	(cd MENTA/extlib && tar cf - --exclude .svn .) | (cd $(NANOADIR)/extlib && tar xf -)
	(cd MENTA/lib && tar cf - MENTA/Template.pm) | (cd $(NANOADIR)/extlib && tar xf -)
EOM

foreach my $file (@extra_files) {
    $postamble .= <<"EOM";
	\$(CP) $file \$(NANOADIR)/$file
EOM
}

postamble($postamble);

WriteAll;
