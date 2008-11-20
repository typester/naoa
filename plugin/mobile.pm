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
        'postrun',
        \&_postrun,
    );
}

sub _postrun {
    my ($app, $bodyref) = @_;
    
    my $charset = _mobile_encoding($app->mobile_agent);
    $app->header_add(
        -charset => $charset,
    );
    $$bodyref = encode($charset, $$bodyref);
}

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
