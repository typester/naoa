package system::plugin::counter;

use strict;
use warnings;
use utf8;

sub run {
    my ($app, $c) = @_;
    
    # 指定された名前、あるいはコントローラのパッケージ名を名前に使う
    my $counter_name = $c && $c->{name} || ref $app;
    $counter_name =~ s/::/./g;
    
    # config オブジェクトを取得 (今回は system の config に保存)
    my $config = $app->config->system_config;
    
    # カウンタの値を設定データベースからロード
    my $cnt = $config->prefs("counter.$counter_name") || 1;
    
    # +1 した値を保存
    $config->prefs("counter.$counter_name", $cnt + 1);
    
    # カウンタの値を返す
    $cnt;
}

1;
