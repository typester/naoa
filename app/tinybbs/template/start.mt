<?= $app->render('system/header') ?>
<h2>サンプル掲示板</h2>

<?= $app->form->render($app) ?>

? for my $m (@{$c->{messages}}) {

<hr />
<h3><?= $m->{id} ?>. <?= $m->{title} ?></h3>
<?= $m->{body} ?>

? }

<hr />
<a href="http://coderepos.org/share/browser/lang/perl/NanoA/trunk/app/tinybbs">view source code</a>
<?= $app->render('system/footer') ?>
