<%=r $app->render('system/header') %>

<h2>開発版のダウンロード</h2>
<p>
Subversion を使用して、<a href="http://svn.coderepos.org/share/lang/perl/NanoA/trunk/">svn.coderepos.org/share/lang/perl/NanoA/trunk</a> からソースコードをダウンロードします。ダウンロードしたディレクトリを HTTP アクセス可能なディレクトリに移動すれば、動作を開始します。
</p>
<p>
以下の例では、http://host/~user/nanoa/ というディレクトリが、NanoA のインストール先になります。
</p>
<pre>
 % svn co http://svn.coderepos.org/share/lang/perl/NanoA/trunk
 % mv trunk ~/public_html/nanoa
</pre>

<%=r $app->render('system/footer') %>
