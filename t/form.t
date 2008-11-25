use strict;
use warnings;
use utf8;

use Test::More tests => 19;

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
            options    => [
                ''       => { label => '-',  selected => 1 },
                'male'   => { label => '男性' },
                'female' => { label => '女性' },
            ],
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
is($f->elements->[0]->label, q(Username), 'label');
is($f->elements->[0]->min_length, 6, 'min_length');
is($f->elements->[0]->max_length, 8, 'max_length');
like($f->elements->[0]->validate([ 'aaaaa' ])->message, qr/短すぎ/, 'min_length error');
like($f->elements->[0]->validate([ 'aaaaaaaaa' ])->message, qr/長すぎ/, 'max_length error');
like($f->elements->[0]->validate([ '$-13409' ])->message, qr/無効/, 'regexp error');
ok(! $f->elements->[0]->validate([ 'michael' ]), 'ok');
is(${$f->elements->[0]->to_html},
   '<input name="username" type="text" />',
   'to_html',
);

is_deeply($f->elements->[1]->options, [
    ''     => { label => '-', selected => 1 },
    male   => { label => '男性' },
    female => { label => '女性' },
], 'options');
ok(! $f->elements->[1]->validate([ '' ]), 'ok');
is(${$f->elements->[1]->to_html},
   '<select name="sex"><option value="" selected>-</option><option value="male">男性</option><option value="female">女性</option></select>',
   'to_html',
);
