use strict;
use warnings;
use utf8;

use Test::More tests => 18;

use NanoA;

BEGIN { use_ok('NanoA::Form'); };

my $f = NanoA::Form->new(
    secure   => 1,
    elements => [
        input => {
            type       => 'text',
            name       => 'username',
            min_length => 6,
            max_length => 8,
            regexp     => qr/^[0-9a-z_]{6,8}$/,
        },
        select => {
            name       => 'sex',
            required   => undef,
            option     => [ '', qw/male female/ ],
            selected   => '',
        },
    ],
);
is(ref $f, 'NanoA::Form', 'post-new');
ok($f->secure, 'secure flag');
is(scalar @{$f->elements}, 2, '# of elements');
is(ref $f->elements->[0], q(NanoA::Form::Element), 'element object');
is($f->elements->[0]->tag, q(input), 'tag');
is($f->elements->[0]->type, q(text), 'type');
is($f->elements->[0]->name, q(username), 'name');
is($f->elements->[0]->dispname, q(Username), 'dispname');
is($f->elements->[0]->min_length, 6, 'min_length');
is($f->elements->[0]->max_length, 8, 'max_length');
like($f->elements->[0]->validate([ 'aaaaa' ])->message, qr/短すぎ/, 'min_length error');
like($f->elements->[0]->validate([ 'aaaaaaaaa' ])->message, qr/長すぎ/, 'max_length error');
like($f->elements->[0]->validate([ '$-13409' ])->message, qr/無効/, 'regexp error');
ok(! $f->elements->[0]->validate([ 'michael' ]), 'ok');

ok(! $f->elements->[1]->required, 'required');
is_deeply($f->elements->[1]->option, [ '', qw/male female/ ], 'option');
ok(! $f->elements->[1]->validate([]), 'ok');
