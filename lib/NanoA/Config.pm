package NanoA::Config;

use strict;
use warnings;
use utf8;

sub new {
    my ($klass, $opts) = @_;
    bless {
        %$opts,
        global       => undef,
        prerun       => undef,
        postrun      => undef,
        camelize     => undef,
        loaders      => [
            \&NanoA::Dispatch::load_mojo_template,
            \&NanoA::Dispatch::load_pm,
        ],
        not_found    => 'system/not_found',
        mt_cache_dir => "/tmp/nanoa.${NanoA::VERSION}.$>.mt_cache",
        $opts ? %$opts : (),
    }, $klass;
}

sub global_config {
    my ($self, $n) = @_;
    unless ($self->{global}) {
        $self->{global} = {
            dbi_uri => 'dbi:SQLite:dbname=' . $self->data_dir() . '/%s.db',
        };
        # TODO: load {$self->data_dir}/nanoa-global.conf
    }
    $self->{global}->{$n};
}

sub data_dir {
    my $self = shift;
    my $conf = NanoA::read_file('nanoa-conf.cgi');
    $conf =~ /(?:^|\n)data_dir\s*=\s*(.*)/
        or die "nanoa-conf.cgi に data_dir が設定されていません\n";
    my $d = $1;
    my $use_htaccess = $^O =~ /win32/i ? $d !~ m|^[a-z]:[\\\/]| : $d !~ m|/|;
    if ($use_htaccess && ! $ENV{NANOA_USE_HTACCESS}) {
            die << 'EOT';
この実行環境は .htaccess ファイルによるアクセス制御をサポートしていません。
nanoa-conf.cgi に、nanoa 配下以外のディレクトリを絶対パスで指定してください。
EOT
            ;
        }
    unless (-d $d) {
        mkdir $d
            or die << "EOT";
データ用のディレクトリ「$d」が存在しなかったため、作成を試みましたが失敗しました。
nanoa-conf.cgi の設定を確認してください
EOT
        ;
    }
    if ($use_htaccess && ! -e "$d/.htaccess") {
        open my $fh, '>', "$d/.htaccess"
            or die "$d/.htaccess を作成できません:$!";
        print $fh "Deny from All\nOrder deny,allow\n";
        close $fh;
    }
    $d;
}

sub app_name {
    my $self = shift;
    $self->{app_name};
}

sub prerun {
    my $self = shift;
    $self->{prerun};
}

sub postrun {
    my $self = shift;
    $self->{postrun};
}

sub camelize {
    my $self = shift;
    $self->{camelize};
}

sub loaders {
    my $self = shift;
    $self->{loaders};
}

sub not_found {
    my $self = shift;
    $self->{not_found};
}

sub mt_cache_dir {
    my $self = shift;
    $self->{mt_cache_dir};
}

"ENDOFMODULE";
