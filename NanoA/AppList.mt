<%= $app->include('NanoA/header') %>
Thank you for installing NanoA.  Following applications are currently available.
<ul>
% foreach my $dir (<*/start.*>) {
%   next if $dir =~ /~$/;
%   $dir =~ s|/.*$||;
<li><a href="nanoa.cgi/<%= $dir %>/"><%= $dir %></a></li>
% }
</ul>
<%= $app->include('NanoA/footer') %>

