<html>
<head>
<title>hello world</title>
</head>
<body>
Hello to <%= $_[0]->query->param('user') || '' %>.
</body>
</html>
