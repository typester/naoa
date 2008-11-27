package NanoA;

use strict;
use warnings;
use utf8;

our $VERSION = '0.12';

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
    my $self;
    $self = bless {
        config        => $config,
        query         => sub {
            require_once('CGI/Simple.pm');
            no warnings "all"; # suppress 'used only once'
            $CGI::Simple::PARAM_UTF8 = 1;
            CGI::Simple->new();
        },
        headers       => { # prefined headers are unique (only set once)
            -type    => 'text/html',
            -charset => 'utf-8',
        },
        stash         => {},
    }, $klass;
    $self;
}

sub run_hooks {
    my $self = shift;
    my $mode = shift;
    my $klass = ref $self;
    my @hooks;
    if (my $h = $HOOKS{$mode}->{$klass}) {
        push @hooks, @$h;
    }
    if ($klass =~ /^([^:]+)/) {
        if (my $h = $HOOKS{$mode}->{$1 . '::config'}) {
            push @hooks, @$h;
        }
    }
    return
        unless @hooks;
    $_->[0]->($self, @_)
        for sort { $a->[1] <=> $b->[1] } @hooks;
}

sub register_hook {
    my ($klass, $mode, $func, $prio) = @_;
    $prio ||= 50;
    die 'unknown hook: ' . $mode. "\n"
        unless $HOOKS{$mode};
    my $hooks = $HOOKS{$mode}->{ref $klass || $klass} ||= [];
    unless (grep { $_->[0] == $func } @$hooks) {
        push @$hooks, [
            $func,
            $prio,
        ];
    }
}

sub query {
    my $self = shift;
    return $self->{query} = shift
        if @_;
    $self->{query} = $self->{query}->($self)
        if ref $self->{query} eq 'CODE';
    $self->{query};
}

sub header {
    my $self = shift;
    my $h = $self->{headers};
    if (@_ == 0) {
        return $h;
    } elsif (@_ == 1) {
        my $name = lc shift;
        my $v = $h->{$name}
            or return;
        return wantarray ? @$v : $v->[0]
            if ref $v eq 'ARRAY';
        return $v;
    } else {
        die "Usage error: \$app->header() or \$app->header(name) or \$app->header(n1 => v1, n2 => v2)\n"
            if @_ % 2 != 0;
        while (@_) {
            my $n = lc shift;
            $n =~ s/^([^-])/-$1/;
            my $v = shift;
            $v = [ $v ]
                unless ref $v eq 'ARRAY';
            if (exists $h->{$n}) {
                if (ref $h->{$n} eq 'ARRAY') {
                    # exists as an array, just add
                    push @{$h->{$n}}, @$v;
                } else {
                    # exists as an scalar, just replace
                    $h->{$n} = $v->[0];
                }
            } else {
                $h->{$n} = [ @$v ];
            }
        }
        return $h;
    }
}

sub redirect {
    my ($self, $uri, $status) = @_;
    unless ($uri) {
        $uri = nanoa_uri() . '/' . package_to_path(ref $self);
    }
    $status ||= 302;
    print 'Status: ', $status, "\nLocation: " . $uri . "\n\n";
    CGI::ExceptionManager::detach();
}

sub render {
    my ($self, $path, $c) = @_;
    return NanoA::Dispatch->dispatch_as($path, $self, $c);
}

sub package_to_path {
    my $pkg = shift;
    $pkg =~ s|::|/|g;
    $pkg =~ s|/start$|/|;
    $pkg;
}

sub escape_html {
    my $str = shift;
    return $$str
        if ref $str eq 'MENTA::Template::raw_string';
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    return $str;
}

# create raw string (that does not need to be escaped)
sub raw_string {
    my $s = shift;
    ref $s eq 'MENTA::Template::RawString'
        ? $s
            : bless \$s, 'MENTA::Template::RawString';
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
    print 'Content-Type: ', $ct, "\n";
    foreach my $n (sort keys %$headers) {
        my $v = $headers->{$n};
        $n =~ s/^-//;
        $n =~ tr/_/-/;
        if (ref $v eq 'ARRAY') {
            foreach my $vv (@$v) {
                print ucfirst($n), ': ', $vv, "\n";
            }
        } else {
            print ucfirst($n), ': ', $v, "\n";
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
    if (do $path) {
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

sub read_file {
    my $fname = shift;
    open my $fh, '<:utf8', $fname or die 'cannot read ' . $fname. ":$!";
    my $s = do { local $/; join '', <$fh> };
    close $fh;
    $s;
}

sub __insert_methods {
    my $module = shift;
    no strict 'refs';
    *{$module . '::' . $_} = \&{$_}
        for qw(raw_string escape_html);
}

"ENDOFMODULE";
