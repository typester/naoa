<html>
<head>
<title>hello world</title>
</head>
<body>
Hello to <%= h($app->query->param('user') || '') %>.
<hr>
<%= $app->render('example/copyright') %>
</body>
</html>
