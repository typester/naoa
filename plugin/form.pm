package plugin::form;

use strict;
use warnings;
use utf8;

use NanoA::Form;
use plugin::session;

use base qw(NanoA::Plugin);

sub init_plugin {
    my ($klass, $controller) = @_;
    plugin::session->init_plugin($controller);
    no strict 'refs';
    no warnings 'redefine';
    my $form;
    *{$controller . '::form'} = sub { $form };
    *{$controller . '::define_form'} = sub {
        $form = NanoA::Form->new(
            action => NanoA->nanoa_uri . '/' . NanoA::package_to_path($controller),
            @_ == 1 ? %{$_[0]} : @_,
        );
    };
}

1;
