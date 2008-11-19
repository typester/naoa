<?=r $app->render('system/header') ?>

<h2 id="install">インストール</h2>
<p>
まず、<a href="install">インストール</a>の説明に従って、NanoA をインストールします。インストールが完了すると、<a href="<?= $app->nanoa_uri ?>">こちら</a>の画面が表示されるようになります。
</p>

<h2 id="helloworld">Helloworld の作成</h2>
<p>
app/hello というディレクトリを作成し、以下のようなファイル (start.mt) を置きます。
</p>
<div class="pre_caption">app/hello/start.mt</div>
<pre>
こんにちは、&lt;?= $app->query->param('user') ?&gt;さん
</pre>
<p>
続いて、NanoA のトップページをリロードしてみましょう。hello というアプリケーションが増えているはずです (今あなたが書いたアプリケーションです) 。そのアプリケーション名をクリックすると、「こんにちは、さん」と表示されます。
</p>
<p>$app->query->param('user') は、クエリパラメータ「user」を読み取るためのおまじないです。nanoa.cgi/hello/?user=太郎 という URL にアクセスすると、「こんにちは、太郎さん」と表示されます。
</p>
<div class="column">
<h3>クエリパーサについて</h3>
<p>
NanoA は、クエリパーサとして <a href="http://search.cpan.org/dist/CGI-Simple/">CGI::Simple</a> を同梱しています。上記の $app->query は、クエリオブジェクトを取得する処理です。リクエストのパースやファイルアップロードの受信、クッキー処理の手法については、CGI::Simple のドキュメントをご参照ください。
</p>
</div>

<h2 id="split_template">テンプレートの分離</h2>

<h2 id="database">データベース接続</h2>

<h2 id="config">アプリケーションの設定</h2>

<h2 id="hooks">アプリケーションのフック</h2>

<h2 id="mobile">ケータイ対応</h2>
<p>
mobile_carrier_longname 関数を呼び出すことで、携帯端末のキャリアを判定することが可能です。返り値の値は、HTTP::MobileAgent に準じます<sup>注1</sup>。
</p>
<pre>
sub run {
    my $app = shift;
    ...
    my $carrier = $app->mobile_carrier_longname;
    return "あなたのブラウザは $carrier です";
}
</pre>
<p style="text-align: center;">
実行例: 「あなたのブラウザは <?= $app->mobile_carrier_longname ?> です」
</p>
<div>
注1: MENTA からコピーしました thanks to tohuhirom
</div>
<?=r $app->render('system/footer') ?>
