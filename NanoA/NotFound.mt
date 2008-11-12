% my $pi = $app->query->path_info;
% return $app->include('NanoA/AppList') unless $pi;
<% $app->header_add(-status => 404); %>
<%= $app->include('NanoA/header') %>
Not Found.  The list of installed applications can be found: <a href=".">here</a>.
<%= $app->include('NanoA/footer') %>
