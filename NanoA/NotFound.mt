% my $pi = $app->query->path_info;
% return $app->render('NanoA/AppList') unless $pi;
<% $app->header_add(-status => 404); %>
<%= $app->render('NanoA/header') %>
Not Found.  The list of installed applications can be found: <a href="<%= h($app->nanoa_uri) %>">here</a>.
<%= $app->render('NanoA/footer') %>
