package plugin::session;

use strict;
use warnings;
use utf8;

use HTTP::Session;
use HTTP::Session::Store::DBM;
use HTTP::Session::State::Cookie;

use base qw(NanoA::Plugin);

sub init_plugin {
    my ($klass, $controller) = @_;
    # add funcs to caller
    NanoA::register_hook($controller, 'postrun', \&_postrun);
}

sub _postrun {
    my ($app, $bodyref) = @_;
    $app->session->header_filter($app);
}

sub run {
    my $self = shift;
    return $self->render('plugin/template/session');
}

no warnings 'redefine';

sub NanoA::session {
    my $app = shift;
    $app->{stash}->{'plugin::session'} ||= HTTP::Session->new(
        store   => HTTP::Session::Store::DBM->new(
            file => join('/', $app->config->data_dir, 'session.dbm'),
        ),
        state   => HTTP::Session::State::Cookie->new(),
        request => $app->query,
        id      => 'HTTP::Session::ID::MD5',
    );
}

1;
