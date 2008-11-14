# NOTES:
#   このファイル、およびlibはあくまで開発者向けのもので、ユーザーには
#       nanoa.cgi
#       template/not_found.mt
#       template/app_list.mt
#       template/header.mt
#       template/footer.mt
#   の4ファイルのみを提供する。
#
#   nanoa.cgiはmake nanoaで作成される

use inc::Module::Install;

name('NanoA');
all_from('lib/NanoA.pm');

# requires には Perl 5.8にデフォルトでインストールされているもの以外は
# 使ってはいけません

# ここでnanoaルールを定義
postamble(<<'EOM');
NANOADIR = dist-cgi
NANOATMPLDIR = $(NANOADIR)/template
NANOACGI = template/nanoa.cgi
NANOATMPL = \
	template/not_found.mt \
	template/app_list.mt \
	template/header.mt \
	template/footer.mt

nanoadir: 
	if [ ! -d $(NANOADIR) ]; then \
		$(MKPATH) $(NANOADIR); \
	fi
	if [ ! -d $(NANOATMPLDIR) ]; then \
		$(MKPATH) $(NANOATMPLDIR); \
	fi

nanoacgi: $(TO_INST_PM)
	$(FULLPERLRUN) -e ' \
		print "#!$$^X\n"; \
		foreach my $$file (@ARGV) { \
			local @ARGV = ($$file); \
			while (<>) { last if /^"ENDOFMODULE";$$/; print } \
		} \
		print "1;\n";\
	' $(NANOACGI) $(TO_INST_PM) > $(NANOADIR)/nanoa.cgi

nanoatmpl: $(NANOATMPL)
	tar cf - $+ | (cd $(NANOADIR) && tar xf -)

nanoa: nanoadir nanoacgi nanoatmpl
	$(NOOP)

EOM

WriteAll;