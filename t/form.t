use strict;
use warnings;
use utf8;

use Test::More tests => 46;

use lib qw(MENTA/extlib);
use NanoA;
use Class::Accessor::Lite; # usally loaded (or bundled) in nanoa.cgi

BEGIN { use_ok('NanoA::Form'); };

my $form = NanoA::Form->new(
    secure => 1,
    action => '/action',
    fields => [
        username => {
            type       => 'text',
            class      => 'hoge_class',
            value      => 'def"val',
            # validation
            required   => 1,
            min_length => 6,
            max_length => 8,
            regexp     => qr/^[0-9a-z_]{6,8}/,
        },
        # TODO add test for hidden fields
        sex => {
            type    => 'radio',
            options => [
                male   => { label => '男性' },
                female => { label => '女性' },
            ],
            # validation
            required => 1,
        },
        age => {
            type => 'select',
            options => [
                '' => { label => '選択してください', selected => 1 },
                19 => { label => '〜19才' },
                20 => { label => '20才〜29才' },
                30 => { label => '30才〜39才' },
                40 => { label => '40才〜49才' },
                50 => { label => '50才〜59才' },
                99 => { label => '60才以上' },
            ],
            # validation
            required => 1,
        },
        interest => {
            type => 'checkbox',
            options => [
                c    => { label => 'C/C++' },
                perl => { label => 'perl', checked => 1 },
                php  => { label => 'PHP' },
                ruby => { label => 'Ruby' },
            ],
            # validation
            required => [ 2, 3 ],
        },
    ],
);
my $dummy = << 'EOT';
        comment => {
            type => 'textarea',
            # validation
            required => 0,
        },
    ],
);
EOT

is(ref $form, 'NanoA::Form', 'post-new');
ok($form->secure, 'secure flag');
is(scalar @{$form->fields}, 4, '# of fields');

my $field = $form->fields->[0];
is(ref $field, q(NanoA::Form::Field::Text), 'field object');
is($field->type, q(text), 'text type');
is($field->name, q(username), 'text name');
is($field->label, q(Username), 'text label');
is($field->min_length, 6, 'text min_length');
is($field->max_length, 8, 'text max_length');
like($field->validate([ 'aaaaa' ])->message, qr/短すぎ/, 'text min_length error');
like($field->validate([ 'aaaaaaaaa' ])->message, qr/長すぎ/, 'text max_length error');
like($field->validate([ '$-13409' ])->message, qr/無効/, 'text regexp error');
ok(! $field->validate([ 'michael' ]), 'text regexp');
is(${$field->to_html},
   '<input class="hoge_class" name="username" type="text" value="def&quot;val" />',
   'text to_html',
);
is(${$field->to_html([ 'hoge' ])},
   '<input class="hoge_class" name="username" type="text" value="hoge" />',
   'text to_html 2',
);

$field = $form->fields->[1];
is($field->type, q(radio), 'radio type');
like($field->validate([])->message, qr/選択してください/, 'radio required');
like($field->validate([ 'nonexistent' ])->message, qr/不正な/, 'radio unexpected');
like($field->validate([ qw/male female/ ])->message, qr/不正な/, 'radio multi');
ok(! $field->validate([ 'male' ]), 'radio validate');
ok(! $field->validate([ 'female' ]), 'radio validate 2');
like(${$field->options->[0]->to_html},
     qr{<input id=".*?" name="sex" type="radio" value="male" /><label for=".*?">男性</label>},
     'radio to_html',
);
like(${$field->to_html},
     qr{<input id=".*?" name="sex" type="radio" value="male" /><label for=".*?">男性</label>\s*<input id=".*?" name="sex" type="radio" value="female" /><label for=".*?">女性</label>},
     'radio to_html 2',
);
like(${$field->to_html([ 'male' ])},
     qr{<input checked="1" id=".*?" name="sex" type="radio" value="male" /><label for=".*?">男性</label>\s*<input id=".*?" name="sex" type="radio" value="female" /><label for=".*?">女性</label>},
     'radio to_html 3',
);

$field = $form->fields->[2];
is($field->type, q(select), 'select type');
like($field->validate([])->message, qr/選択してください/, 'select required');
like($field->validate([ 'x' ])->message, qr/不正な/, 'select unexpected');
like($field->validate([ '' ])->message, qr/選択してください/, 'select required');
like($field->validate([ qw/20 30/ ])->message, qr/不正な/, 'select multi');
ok(! $field->validate([ 20 ]), 'select validate');
ok(! $field->validate([ 30 ]), 'select validate 2');
is(${$field->options->[0]->to_html},
   '<option selected="1" value="">選択してください</option>',
   'select to_html 1',
);
is(${$field->options->[1]->to_html},
   '<option value="19">〜19才</option>',
   'select to_html 2',
);
is(${$field->to_html},
   join(
       '',
       '<select name="age">',
       '<option selected="1" value="">選択してください</option>',
       '<option value="19">〜19才</option>',
       '<option value="20">20才〜29才</option>',
       '<option value="30">30才〜39才</option>',
       '<option value="40">40才〜49才</option>',
       '<option value="50">50才〜59才</option>',
       '<option value="99">60才以上</option>',
       '</select>',
   ),
   'select to_html 3',
);
is(${$field->to_html([ 20 ])},
   join(
       '',
       '<select name="age">',
       '<option value="">選択してください</option>',
       '<option value="19">〜19才</option>',
       '<option selected="1" value="20">20才〜29才</option>',
       '<option value="30">30才〜39才</option>',
       '<option value="40">40才〜49才</option>',
       '<option value="50">50才〜59才</option>',
       '<option value="99">60才以上</option>',
       '</select>',
   ),
   'select to_html 3',
);

$field = $form->fields->[3];
is($field->type, q(checkbox), 'checkbox type');
like($field->validate([ 'hoge' ])->message, qr/不正な/, 'checkbox unexpected');
like($field->validate([ qw/perl/ ])->message, qr/の中から 2 〜 3/, 'checkbox required 1');
ok(! $field->validate([ qw/c perl/ ]), 'checkbox required 2');
ok(! $field->validate([ qw/c perl ruby/ ]), 'checkbox required 3');
like($field->validate([ qw/c perl php ruby/ ])->message, qr/の中から 2 〜 3/, 'checkbox required 4');
like(
    ${$field->options->[0]->to_html},
    qr{<input id=".*?" name="interest" type="checkbox" value="c" /><label for=".*?">C/C\+\+</label>},
    'checkbox to_html 1',
);
like(
    ${$field->options->[1]->to_html},
    qr{<input checked="1" id=".*?" name="interest" type="checkbox" value="perl" /><label for=".*?">perl</label>},
    'checkbox to_html 2',
);
like(
    ${$field->to_html},
    qr{<input id=".*?" name="interest" type="checkbox" value="c" /><label for=".*?">C/C\+\+</label> <input checked="1" id=".*?" name="interest" type="checkbox" value="perl" /><label for=".*?">perl</label> <input id=".*?" name="interest" type="checkbox" value="php" /><label for=".*?">PHP</label> <input id=".*?" name="interest" type="checkbox" value="ruby" /><label for=".*?">Ruby</label>},
    'checkbox to_html 3',
);
like(
    ${$field->to_html([ qw/perl php/ ])},
    qr{<input id=".*?" name="interest" type="checkbox" value="c" /><label for=".*?">C/C\+\+</label> <input checked="1" id=".*?" name="interest" type="checkbox" value="perl" /><label for=".*?">perl</label> <input checked="1" id=".*?" name="interest" type="checkbox" value="php" /><label for=".*?">PHP</label> <input id=".*?" name="interest" type="checkbox" value="ruby" /><label for=".*?">Ruby</label>},
    'checkbox to_html 3',
);
