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
E_EXTLIBS = \
	extlib/MENTA/Template.pm

nanoadir: 
	$(NOECHO)if [ ! -d $(NANOADIR) ]; then \
		$(NOECHO)$(MKPATH) $(NANOADIR); \
	fi
	$(NOECHO)if [ ! -d $(NANOATMPLDIR) ]; then \
		$(NOECHO)$(MKPATH) $(NANOATMPLDIR); \
	fi

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
	' $(NANOACGI) $(TO_INST_PM) $(INCLUDE_EXTLIBS) > $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(CHMOD) 755 $(NANOADIR)/nanoa.cgi
	$(NOECHO)$(ECHO) "Generated $(NANOADIR)/nanoa.cgi"

nanoatmpl: $(NANOATMPL)
	$(NOECHO)tar cf - $+ | (cd $(NANOADIR) && tar xf -)

nanoaextlib: 
	$(MKPATH) $(NANOADIR)/extlib/CGI/Simple
	$(CP) extlib/CGI/Simple.pm $(NANOADIR)/extlib/CGI/Simple.pm
	$(CP) extlib/CGI/Simple/Cookie.pm $(NANOADIR)/extlib/CGI/Simple/Cookie.pm
	$(CP) extlib/CGI/Simple/Util.pm $(NANOADIR)/extlib/CGI/Simple/Util.pm

nanoa: nanoadir nanoacgi nanoatmpl nanoaextlib
	$(NOECHO)$(NOOP)

EOM

WriteAll;