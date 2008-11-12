<html>
<head>
<title>hello world</title>
</head>
<body>
Hello to <%= $app->query->param('user') || '' %>.
<hr>
<%= $app->include('copyright') %>
</body>
</html>
