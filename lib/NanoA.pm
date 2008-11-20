package NanoA;

use strict;
use warnings;
use utf8;

our $VERSION = '0.07';

my %REQUIRED;
my %LOADED;
my %HOOKS;

BEGIN {
    %REQUIRED = ();
    %LOADED = ();
    %HOOKS = (
        prerun  => {},
        postrun => {},
    );
};

sub new {
    my ($klass, $config) = @_;
    my $self = bless {
        config        => $config,
        query         => undef,
        headers       => {
            -type    => 'text/html',
            -charset => 'utf8',
        },
        stash         => {},
    }, $klass;
    $self;
}

sub run_hooks {
    my $self = shift;
    my $mode = shift;
    my $hooks = $HOOKS{$mode}->{ref $self}
        or return;
    $_->($self, @_)
        for @$hooks;
}

sub register_hook {
    my ($klass, $mode, $func) = @_;
    die "unknown hook: $mode\n"
        unless $HOOKS{$mode};
    my $target = $HOOKS{$mode}->{ref $klass || $klass} ||= [];
    push @$target, $func;
}

sub query {
    my $self = shift;
    unless ($self->{query}) {
        require_once('CGI/Simple.pm');
        no warnings "all"; # suppress 'used only once'
        $CGI::Simple::PARAM_UTF8 = 1;
        $self->{query} = CGI::Simple->new;
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
    my ($self, $uri, $status) = @_;
    $status ||= 302;
    print "Status: $status\nLocation: $uri\n\n";
    CGI::ExceptionManager::detach();
}

sub render {
    my ($self, $path, $c) = @_;
    return NanoA::Dispatch->dispatch_as($path, $self, $c);
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
        my $db_uri = $self->config->db_uri;
        $self->{db} = DBI->connect($db_uri)
            or die DBI->errstr;
        $self->{db}->{unicode} = 1
            if $db_uri =~ /^dbi:sqlite:/i;
    }
    $self->{db};
}

sub mobile_agent {
    my $self = shift;
    require_once('HTTP/MobileAgent.pm');
    $self->{stash}->{'HTTP::MobileAgent'} ||= HTTP::MobileAgent->new();
}

sub read_file {
    my $fname = shift;
    open my $fh, '<:utf8', $fname or die "cannot read $fname:$!";
    my $s = do { local $/; join '', <$fh> };
    close $fh;
    $s;
}

sub __insert_methods {
    my $module = shift;
    no strict 'refs';
    *{"$module\::$_"} = \&{$_}
        for qw(escape_html);
}

"ENDOFMODULE";
