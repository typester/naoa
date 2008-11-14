package NanoA::Config;

use strict;
use warnings;

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
        mt_cache_dir => "/tmp/nanoa.$>.mt_cache",
        $opts ? %$opts : (),
    }, $klass;
}

sub global_config {
    my ($self, $n) = @_;
    unless ($self->{global}) {
        # TODO: load nanoa_config.pm
        $self->{global} = {
            dbi_uri => 'dbi:SQLite:dbname=var/%s.db',
        };
        require 'nanoa_config.pm'
            if -e 'nanoa_config.pm';
    }
    $self->{global}->{$n};
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
