<%= $app->render('example/template/header') %>
<p>
This is NanoA exmaple application.  Thank you for installing.
</p>
<hr />
<p>
There are two ways to write applications using NanoA.
</p>
<p>
One is to write a controller using perl and render a template using Mojo::Template.  This page is generated as such, and the source code can be found <a href="http://coderepos.org/share/browser/lang/perl/NanoA/trunk/example/start.pm">here</a>.
</p>
<p>
The other way is to only write a Mojo::Template file, which acts much like PHP.  <a href="mojo?user=nanashisan">this page</a> is a good example (<a href="http://coderepos.org/share/browser/lang/perl/NanoA/trunk/example/mojo.mt">source code</a>).
</p>
<hr />
<p>
And finally, best wishes to you from <a href="http://labs.cybozu.co.jp/blog/kazuho/">Kazuho Oku</a>, developer of NanoA.
</p>
<%= $app->render('example/template/footer') %>
