% my $pi = $app->query->path_info;
% return $app->render('system/app_list') unless $pi;
<% $app->header_add(-status => 404); %>
<%=r $app->render('system/header') %>
<h2>File Not Found</h2>
File Not Found.  The list of installed applications can be found: <a href="<%= $app->nanoa_uri %>">here</a>.
<%=r $app->render('system/footer') %>
