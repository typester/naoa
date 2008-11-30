package openid::openid;

use strict;
use warnings;
use utf8;

use plugin::session;

use base qw(NanoA::Plugin);

sub _load_lib {
    NanoA::require_once('Net/OpenID/Consumer/Lite.pm');
}

sub init_plugin {
    my ($klass, $controller) = @_;
    plugin::session->init_plugin($controller);
    no strict 'refs';
    no warnings 'redefine';
    my $form;
    *{$controller . '::openid_require_login'} = sub {
        my ($app, $op, $back_uri) = @_;
        return
            if $app->session->get('openid_identity');
        _load_lib();
        $app->redirect(
            Net::OpenID::Consumer::Lite->check_url(
                $op,
                "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}" . $app->uri_for(
                    'openid/openid', {
                        back => $back_uri,
                    },
                ),
            ),
        );
    };
    *{$controller . '::openid_identity'} = sub {
        my $app = shift;
        $app->session->get('openid_identity');
    };
    *{$controller . '::openid_logout'} = sub {
        my $app = shift;
        $app->session->remove('openid_identity');
        $app->session->remove('openid_op_endpoint');
    };
}

sub run {
    my $app = shift;
    
    _load_lib();
    
    # 本当はよくないことだけど、SSL の証明書があってなくてもスルーしちゃう。
    local $Net::OpenID::Consumer::Lite::IGNORE_SSL_ERROR = 1;
    
    my $query = $app->query;
    my $params = +{ map { $_ => $query->param($_) } $query->param };
    Net::OpenID::Consumer::Lite->handle_server_response(
        $params => (
            not_openid => sub {
                die "Not an OpenID message";
            },
            setup_required => sub {
                my $setup_url = shift;
                $app->redirect($setup_url);
            },
            cancelled => sub {
                return 'user cancelled';
            },
            verified => sub {
                my $vident = shift;
                $app->session->regenerate_session_id();
                $app->session->set(
                    'openid_identity',
                    $vident->{identity},
                );
                $app->session->set(
                    'openid_op_endpoint',
                    $vident->{op_endpoint},
                );
                if (my $back_uri = $app->query->param('back')) {
                    $app->redirect($back_uri);
                }
                "logged in";
            },
            error => sub {
                my $err = shift;
                die($err);
            },
        )
    );
}

1;
