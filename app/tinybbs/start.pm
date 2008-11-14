package tinybbs::start;

use strict;
use warnings;

use base qw(NanoA);

sub run {
    my $app = shift;
    my $q = $app->query;
    
    # ignore errors, may exist
    $app->db->do(
        'create table bbs (id integer not null primary key autoincrement,title varchar(255),body text)',
    );

    if ($app->query->request_method eq 'POST') {
        # insert
        $app->db->do(
            'insert into bbs (title,body) values (?,?)',
            {},
            $app->query->param('title'),
            $app->query->param('body'),
        );
        # redirect
        $app->redirect(
            $app->nanoa_uri . '/tinybbs/',
        );
    }
    
    return $app->render('tinybbs/template/start', {
        messages => $app->db->selectall_arrayref(
            'select id,title,body from bbs order by id desc',
            { Slice => {} },
        ),
    });
}

1;
