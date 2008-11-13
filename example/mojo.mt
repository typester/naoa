<%=r $app->render('example/template/header') %>
Hello to <%= $app->query->param('user') || '' %>.
<%=r $app->render('example/template/footer') %>
