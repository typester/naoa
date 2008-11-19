package NanoA;

use strict;
use warnings;
use utf8;

our $VERSION = '0.05';

my %REQUIRED;
my %LOADED;

BEGIN {
    %REQUIRED = ();
    %LOADED = ();
};

sub new {
    my ($klass, $config) = @_;
    my $self = bless {
        config  => $config,
        query   => undef,
        headers => {
            -type    => 'text/html',
            -charset => 'utf8',
        },
        prerun_hooks  => [],
        postrun_hooks => [],
    }, $klass;
    $config->init_app($self);
    $self;
}

sub prerun {
    my $self = shift;
    foreach my $h (@{$self->prerun_hooks}) {
        $h->($self);
    }
}

sub postrun {
    my ($self, $bodyref) = @_;
    foreach my $h (@{$self->postrun_hooks}) {
        $h->($self, $bodyref);
    }
}

sub detach {
    die { finished => 1 };
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

sub prerun_hooks {
    my $self = shift;
    $self->{prerun_hooks};
}

sub postrun_hooks {
    my $self = shift;
    $self->{postrun_hooks};
}

sub redirect {
    my ($self, $uri, $status) = @_;
    $status ||= 302;
    print "Status: $status\nLocation: $uri\n\n";
    $self->detach;
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
    print STDERR "now dying : $@\n"
        if $@;
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

sub mobile_carrier {
    my $self = shift;
    return $self->{mobile_carrier}
        if $self->{mobile_carrier};
    my $re = sub {
        my $DoCoMoRE = '^DoCoMo/\d\.\d[ /]';
        my $JPhoneRE = '^(?i:J-PHONE/\d\.\d)';
        my $VodafoneRE = '^Vodafone/\d\.\d';
        my $VodafoneMotRE = '^MOT-';
        my $SoftBankRE = '^SoftBank/\d\.\d';
        my $SoftBankCrawlerRE = '^Nokia[^/]+/\d\.\d';
        my $EZwebRE  = '^(?:KDDI-[A-Z]+\d+[A-Z]? )?UP\.Browser\/';
        my $AirHRE = '^Mozilla/3\.0\((?:WILLCOM|DDIPOCKET)\;';
        qr/(?:($DoCoMoRE)|($JPhoneRE|$VodafoneRE|$VodafoneMotRE|$SoftBankRE|$SoftBankCrawlerRE)|($EZwebRE)|($AirHRE))/;
    }->();
    if ($self->query->user_agent =~ /$re/) {
        $self->{mobile_carrier} = $1 ? 'I' : $2 ? 'V' : $3 ? 'E' :  'H';
    } else {
        $self->{mobile_carrier} = 'N';
    }
}

sub mobile_carrier_longname {
    my $self = shift;
    {
        N => 'NonMobile',
        I => 'DoCoMo',
        E => 'EZweb',
        V => 'Softbank',
        H => 'AirH',
    }->{$self->mobile_carrier()};
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
