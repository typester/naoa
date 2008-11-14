<html>
<head>
<title>Test BBS</title>
</head>
<body>
<form method="POST">
Title: <input type="text" name="title" size="40" /><br />
Body:<br />
<textarea name="body" rows="10" cols="60">
</textarea>
<input type="submit" value="Submit" />
</form>
% for my $m (@{$c->{messages}}) {
<hr />
<h2><%= $m->{id} %>. <%= $m->{title} %></h2>
<%= $m->{body} %>
% }
</body>
</html>
