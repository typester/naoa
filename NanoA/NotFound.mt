% my $pi = $app->query->path_info;
% return $app->render('NanoA/AppList') unless $pi;
<% $app->header_add(-status => 404); %>
<%=r $app->render('NanoA/header') %>
Not Found.  The list of installed applications can be found: <a href="<%= $app->nanoa_uri %>">here</a>.
<%=r $app->render('NanoA/footer') %>
