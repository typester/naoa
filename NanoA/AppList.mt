<%= $app->render('NanoA/header') %>
Thank you for installing NanoA.  Following applications are currently available.
<ul>
% foreach my $dir (<*/start.*>) {
%   next if $dir =~ /~$/;
%   $dir =~ s|/.*$||;
<li><a href="<%= h($app->nanoa_uri . "/$dir/") %>"><%= h($dir) %></a></li>
% }
</ul>
<%= $app->render('NanoA/footer') %>
