<?=r $app->render('system/header') ?>

<h2 id="install">インストール</h2>
<p>
まず、<a href="install">インストール</a>の説明に従って、NanoA をインストールします。インストールが完了すると、<a href="<?= $app->nanoa_uri ?>">こちら</a>の画面が表示されるようになります。
</p>

<h2 id="helloworld">Helloworld の作成</h2>
<p>
インストールが完了したら、「Hello, world!」と表示するだけのウェブアプリケーションを作成してみましょう。手順は以下のとおりです。
</p>
<ol>
<li>NanoA の app ディレクトリの下に hello ディレクトリを作る</li>
<li>app/hello ディレクトリの下に、start.mt というファイルを配置し、以下のように記述</li>
</ol>
<div class="pre_caption">app/hello/start.mt</div>
<pre>
Hello, world!
</pre>
<p>
ファイルの設置が完了したら、NanoA のトップページをリロードしてみましょう。インストール済のアプリケーション一覧に、hello というアプリケーションが増えているはずです (今あなたが書いたアプリケーションです) 。そのアプリケーション名をクリックすると、「Hello, world!」と表示されるはずです。
</p>
<h2 id="hellouser">クエリ文字列のハンドリング</h2>
<p>
では続いて、クエリ文字列「user」からユーザー名を読み取って、「○○さん、こんにちは」と表示するページを作ってみましょう。
</p>
<div class="pre_caption">app/hello/hello2.mt</div>
<pre>
&lt;?= $app->query->param('user') ?&gt;さん、こんにちは
</pre>
<p>
nanoa.cgi/hello/hello2?user=John を開くと、「Johnさん、こんにちは」と表示されるはずです。user= の後に日本語を書いても大丈夫。ちゃんと日本語の名前が表示されます。
</p>
<p>
NanoA は、クエリパーサとして <a href="http://search.cpan.org/dist/CGI-Simple/">CGI::Simple</a> を同梱しています。リクエストのパースやファイルアップロードの受信、クッキー処理の手法については、CGI::Simple のドキュメントをご参照ください。
</p>

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
