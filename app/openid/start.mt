? use openid::openid
? if ($app->query->param('op')) {
?   if ($app->openid_identity) {
?     $app->redirect();
?   }
?   $app->openid_require_login($app->query->param('op'), $app->uri_for('openid/'));
? } elsif ($app->query->param('logout')) {
?   $app->openid_logout();
?   $app->redirect();
? }
<?= $app->render('system/header') ?>

<h2>OpenID でログインするデモ</h2>

? if ($app->openid_identity) {
あなたは <a href="<?= $app->openid_identity ?>"><?= $app->openid_identity ?></a> としてログイン中です。 <a href="<?= $app->uri_for('openid/?logout=1') ?>">ログアウト</a>
? } else {
<ul>
<li><a href="<?= $app->uri_for('openid/', { op => 'https://mixi.jp/openid_server.pl' }) ?>">Mixi でログイン</a></li>
<li><a href="<?= $app->uri_for('openid/', { op => 'https://auth.livedoor.com/openid/server' }) ?>">Livedoor でログイン</a></li>
</ul>
? }

<?= $app->render('system/footer') ?>
