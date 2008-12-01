package plugin::admin;

use strict;
use warnings;
use utf8;

use base qw(NanoA::Plugin);

use plugin::session;
use plugin::form;

sub init_plugin {
    my ($klass, $controller) = @_;
    plugin::session->init_plugin($controller);
    no strict 'refs';
    no warnings 'redefine';
    *{$controller . '::is_admin'} = sub {
        my $app = shift;
        return $app->session->get('system.is_admin') || undef;
    };
    *{$controller . '::admin_login_uri'} = sub {
        my ($app, $back_uri) = @_;
        if (defined $back_uri) {
            $back_uri = $app->nanoa_uri . '/' . $back_uri
                unless $back_uri =~ m{^(/|[a-z]+://)};
        } else {
            $back_uri = $app->nanoa_uri . ($app->query->path_info() || '');
        }
        $app->uri_for('plugin/admin', {
            back => $back_uri,
        });
    };
    *{$controller . '::openid_logout_uri'} = sub {
        my ($app, $back_uri) = @_;
        if (defined $back_uri) {
            $back_uri = $app->nanoa_uri . '/' . $back_uri
                unless $back_uri =~ m{^(/|[a-z]+://)};
        } else {
            $back_uri = $app->nanoa_uri . ($app->query->path_info() || '');
        }
        $app->uri_for('plugin/admin', {
            back   => $back_uri,
            logout => 1,
        });
    };
}

# since plugin::admin is a plugin itself, explicite initialization is required
plugin::form->init_plugin(__PACKAGE__);

sub run {
    my $app = shift;
    
    if ($app->query->param('logout')) {
        $app->session->remove('system.is_admin');
        $app->redirect($app->query->param('back') || $app->nanoa_uri);
    }
    
    define_form(
        fields => [
            password => {
                type     => 'password',
                label    => '管理用パスワード',
                # validation
                required => 1,
                custom   => sub {
                    my ($field, $query) = @_;
                    my $hash =
                        $app->config->system_config->prefs('system_password');
                    if (crypt($query->param('password'), $hash) ne $hash) {
                        return HTML::AutoForm::Error->CUSTOM(
                            $field,
                            'パスワードが間違っています',
                        );
                    }
                    return;
                },
            },
        ],
    );
    
    if ($app->query->request_method eq 'POST' && $app->validate_form) {
        $app->session->set('system.is_admin', 1);
        $app->redirect($app->query->param('back') || $app->nanoa_uri);
    }
    
    $app->render('plugin/template/admin');
}

1;
