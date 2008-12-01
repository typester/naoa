? use openid::openid

<?= $app->render('system/header') ?>

<h2>OpenID でログインするデモ</h2>

? if (my $user = $app->openid_user) {

あなたは <a href="<?= $user->{identity} ?>"><?= $user->{identity} ?></a> としてログイン中です。 <a href="<?= $app->openid_logout_uri('openid/') ?>">ログアウト</a>

? } else {

<ul>
<li><a href="<?= $app->openid_login_uri('openid/', 'https://mixi.jp/openid_server.pl') ?>">Mixi でログイン</a></li>
<li><a href="<?= $app->openid_login_uri('openid/', 'https://auth.livedoor.com/openid/server') ?>">Livedoor でログイン</a></li>
</ul>

? }

<?= $app->render('system/footer') ?>
