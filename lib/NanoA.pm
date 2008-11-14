package NanoA;

use strict;
use warnings;

my %REQUIRED;
my %LOADED;

BEGIN {
    %REQUIRED = ();
    %LOADED = ();
};

sub new {
    my ($klass, $config) = @_;
    bless {
        config  => $config,
        query   => undef,
        headers => {
            -type    => 'text/html',
            -charset => 'utf8',
        },
    }, $klass;
}

sub prerun {
    my $self = shift;
    if (my $h = $self->config->{prerun}) {
        $h->($self);
    }
}

sub postrun {
    my ($self, $bodyref) = @_;
    if (my $h = $self->config->{postrun}) {
        $h->($self, $bodyref);
    }
}

sub query {
    my $self = shift;
    unless ($self->{query}) {
        my $cgi_klass = $self->config('cgi_klass') || 'CGI::Simple';
        my $cgi_path = $cgi_klass;
        $cgi_path =~ s{::}{/}g;
        require_once("$cgi_path.pm");
        $self->{query} = $cgi_klass->new;
    }
    $self->{query};
}

sub header_add {
    my ($self, %args) = @_;
    $self->{headers}->{$_} = $args{$_}
        for keys %args;
}

sub headers {
    my $self = shift;
    $self->{headers};
}

sub redirect {
    my ($self, $uri) = @_;
    $self->header_add(
        -status   => 302,
        -location => $uri,
    );
}

sub render {
    my ($self, $path, $c) = @_;
    my $module = $path;
    $module =~ s|/|::|g;
    NanoA::TemplateLoader::__load(
        $self->config,
        $module,
        $self->app_dir . "/$path.mt",
    );
    $module->run_as($self, $c);
}

sub escape_html {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    return $str;
}

sub nanoa_uri {
    $ENV{SCRIPT_NAME} || '/nanoa.cgi';
}

sub root_uri {
    my $p = nanoa_uri();
    $p =~ s|/[^/]+$||;
    $p;
}

sub app_dir {
    'app';
}

sub config {
    my $self = shift;
    return $self->{config}->{$_[0]}
        if @_ == 1;
    my %args = @_;
    $self->{config}->{$_} = $args{$_}
        for keys %args;
    $self->{config};
}

sub print_header {
    my $self = shift;
    my $headers = $self->{headers};
    my $ct = delete $headers->{-type};
    if ($ct =~ /;\s*charset=/) {
        delete $headers->{-charset};
    } else {
        $ct .= "; charset=" . delete $headers->{-charset};
    }
    print "Content-Type: $ct\n";
    foreach my $n (sort keys %$headers) {
        my $v = $headers->{$n};
        $n =~ s/^-//;
        $n =~ tr/_/-/;
        if (ref $v eq 'ARRAY') {
            foreach my $vv (@$v) {
                print "$n: $v\n";
            }
        } else {
            print "$n: $v\n";
        }
    }
    print "\n";
}

sub require_once {
    my $path = shift;
    return if $REQUIRED{$path};
    require $path;
    $REQUIRED{$path} = 1;
}

sub load_once {
    my ($path, $mark_path) = @_;
    $mark_path ||= $path;
    return if $LOADED{$mark_path};
    local $@;
    if (do "$path") {
        $LOADED{$mark_path} = 1;
        return 1;
    }
    die $@
        if $@;
    undef;
}

sub loaded {
    my $path = shift;
    $LOADED{$path} = shift
        if @_;
    $LOADED{$path};
}

sub db {
    my $self = shift;
    unless ($self->{db}) {
        require_once('DBI.pm');
        $self->{db} = DBI->connect(
            sprintf(
                $self->config->global_config('dbi_uri'),
                $self->config->app_name,
            ),
        ) or die DBI->errstr;
    }
    $self->{db};
}

sub read_file {
    my $fname = shift;
    open my $fh, '<', $fname or die "cannot read $fname:$!";
    my $s = do { local $/; join '', <$fh> };
    close $fh;
    $s;
}

sub __insert_methods {
    my $module = shift;
    no strict 'refs';
    *{"$module\::$_"} = \&{$_}
        for qw(h);
}

"ENDOFMODULE";
