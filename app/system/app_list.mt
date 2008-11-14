<%=r $app->render('system/header') %>
Thank you for installing NanoA.  Following applications are currently available.
<ul>
% foreach my $dir (<app/*/start.*>) {
%   next if $dir =~ /~$/;
%   $dir =~ s|app/(.*)/[^/]+$|$1|;
<li><a href="<%= $app->nanoa_uri . "/$dir/" %>"><%= $dir %></a></li>
% }
</ul>
<%=r $app->render('system/footer') %>

