<%=r $app->render('system/header') %>
<h2>What is NanoA?</h2>
<div>
NanoA is a lightweight web application framework &amp; container, written in perl, especially suitable for CGI-based environments.  The goal is to create an easy-to-use web application framework, at the same time to provide a rich set of applications, so that with the two together it would become an environment that boosts the productivity of web developers.
</div>
<h2>Installed Applications</h2>
<div>
Thank you for installing NanoA.  Following applications are currently available.
<ul>
% foreach my $dir (<app/*/start.*>) {
%   next if $dir =~ /~$/;
%   $dir =~ s|app/(.*)/[^/]+$|$1|;
<li><a href="<%= $app->nanoa_uri . "/$dir/" %>"><%= $dir %></a></li>
% }
</ul>
</div>
<%=r $app->render('system/footer') %>

