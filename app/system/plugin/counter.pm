package system::plugin::counter;

sub run_as {
    my ($klass, $app, $c) = @_;
    
    # 指定された名前、あるいはコントローラのパッケージ名を名前に使う
    my $counter_name = $c && $c->{name} || ref $app;
    $counter_name =~ s/::/./g;
    
    # カウンタの値を設定データベースからロード
    my $cnt = $app->config->prefs("counter.$counter_name") || 1;
    
    # +1 した値を保存
    $app->config->prefs("counter.$counter_name", $cnt + 1);
    
    # カウンタの値を返す
    $cnt;
}

1;
