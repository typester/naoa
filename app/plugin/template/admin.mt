<?= $app->render('plugin/template/header', { title => 'Admin プラグイン' }) ?>

<h2 id="session">Admin プラグイン</h2>

<p>
Admin プラグインを利用して、管理者権限でのログイン状態を制御することができます。
</p>

<div class="pre_caption">管理者としてログイン済でなければログインページへリダイレクト (.pm)</div>
<pre>
use plugin::admin;

# このページの操作には管理者権限が必要
sub run {
    ...
    $app->redirect($app->admin_login_uri)
        unless $app->is_admin;
    ...
</pre>

<?= $app->render('system/footer') ?>
