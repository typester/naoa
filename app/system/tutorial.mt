<%=r $app->render('system/header') %>

<h2 id="install">インストール</h2>
<p>
まず、<a href="install">インストール</a>の説明に従って、NanoA をインストールします。インストールが完了すると、<a href="<%= $app->nanoa_uri %>">こちら</a>の画面が表示されるようになります。
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

<h2 
<h2 id="hello_user">「○○さん、こんにちは」の作成</h2>
<p>
いつまで書いててもおわんないよ ToT
</p>

<h2>以下続く。</h2>
<ul>
<li>ふたつめのコントローラー＜/li>
<li>テンプレートの分離</li>
<li>データベース接続</li>
</ul>

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
実行例: 「あなたのブラウザは <%= $app->mobile_carrier_longname %> です」
</p>
<div>
注1: MENTA からコピーしました thanks to tohuhirom
</div>
<%=r $app->render('system/footer') %>
