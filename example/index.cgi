#! /usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use NanoA;

NanoA::Dispatch->dispatch({
    prefix => 'MyApp',
    # camelize => 1,
    # prerun => sub {},
    # postrun => sub {},
    # dbh => DBI->connect(...),
    # some_config => xyz,
});
