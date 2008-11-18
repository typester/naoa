<?=r $app->render('system/header') ?>
<h2>NanoA ってなに?</h2>
<div>
NanoA は、気軽に使えるウェブアプリケーション実行環境です。その特徴は以下のとおり。
<ul>
<li>初心者でも簡単にアプリケーションを作成可能</li>
<li>レンタルサーバに最適 (suEXEC 環境で設定不要、CGI として高速に動作)</li>
<li>データベース管理や設定の手間は、フレームワーク同梱のシステムアプリケーションにおまかせ (予定)</li>
<li>モダンな Perl のオブジェクト指向フレームワーク</li>
<li><a href="<?= $app->nanoa_uri ?>/system/tutorial#mobile">ケータイ対応</a></li>
</ul>
</div>

<h2>インストール済のアプリケーション</h2>

<div>
NanoA をインストールいただきありがとうございます。現在、以下のアプリケーションが実行可能です。
<ul>
? foreach my $dir (<app/*/start.*>) {
?   next if $dir =~ /~$/;
?   $dir =~ s|app/(.*)/[^/]+$|$1|;
<li><a href="<?= $app->nanoa_uri . "/$dir/" ?>"><?= $dir ?></a></li>
? }
</ul>
</div>
<?=r $app->render('system/footer') ?>
