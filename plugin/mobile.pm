package plugin::mobile;

use strict;
use warnings;
use utf8;

use Encode;

sub import {
    my $pkg = caller;
    # add funcs to caller
    NanoA::register_hook(
        $pkg,
        'prerun',
        \&_prerun,
    );
    NanoA::register_hook(
        $pkg,
        'postrun',
        \&_postrun,
    );
}

sub _prerun {
    my $app = shift;
    my $charset = _mobile_encoding($app->mobile_agent);
    
    return
        if $charset eq 'utf-8';
    
    # build query object by myself and register it, since in first prerun,
    # there is no query object yet
    do {
        NanoA::require_once('CGI/Simple.pm');
        local $CGI::Simple::PARAM_UTF8 = undef;
        my $q = CGI::Simple->new();
        # error occurs when trying to replace contents using Vars
        for my $n ($q->param) {
            my @v = $q->param($n);
            if (@v >= 2) {
                $_ = decode($charset, $_)
                    for @v;
                $q->param($n, \@v);
            } else {
                $q->param($n, decode($charset, $v[0]));
            }
        }
        $app->query($q);
    };
}

sub _postrun {
    my ($app, $bodyref) = @_;
    my $charset = _mobile_encoding($app->mobile_agent);
    
    return
        if $charset eq 'utf-8';
    
    $app->header_add(
        -charset => $charset eq 'cp932' ? 'Shift_JIS' : $charset,
    );
    $$bodyref = encode($charset, $$bodyref);
}

# taken from MENTA
sub _mobile_encoding {
    my $ma = shift;
    return 'utf-8' if $ma->is_non_mobile;
    # docomo の 3G 端末では utf8 の表示が保障されている
    return 'utf-8' if $ma->is_docomo && $ma->xhtml_compliant;
    # softbank 3G の一部端末は cp932 だと絵文字を送ってこない不具合がある
    return 'utf-8' if $ma->is_softbank && $ma->is_type_3gc;
    # au は https のときに utf8 だと文字化ける場合がある
    return 'cp932';
}

1;
