<%=r $app->render('template/header') %>
Thank you for installing NanoA.  Following applications are currently available.
<ul>
% foreach my $dir (<*/start.*>) {
%   next if $dir =~ /~$/;
%   $dir =~ s|/.*$||;
<li><a href="<%= $app->nanoa_uri . "/$dir/" %>"><%= $dir %></a></li>
% }
</ul>
<%=r $app->render('template/footer') %>

