<%=r $app->render('system/header') %>
<h2 id="mobile">ケータイ対応</h2>
<p>
mobile_carrier_longname 関数を呼び出すことで、携帯端末のキャリアを判定することが可能です。返り値の値は、HTTP::MobileAgent に準じます<sup>注1</sup>。
</p>
<pre>
sub run {
    my $app = shift;
    ...
    my $carrier = $app->mobile_carrier_longname;
    print "あなたのブラウザは $carrier です";
}
</pre>
<p style="text-align: center;">
実行例: 「あなたのブラウザは <%= $app->mobile_carrier_longname %> です」
</p>
<div>
注1: MENTA からコピーしました thanks to tohuhirom
</div>
<%=r $app->render('system/footer') %>
