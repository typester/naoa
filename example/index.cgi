#! /usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use NanoA;

NanoA::Dispatch->dispatch({
    prefix => 'MyApp',
    # camelize => 1,                  # camelize package names
    # prerun => sub {},               # prerun hook
    # postrun => sub {},              # postrun hook
    # mt_cache_dir => '/tmp/mt.cache' # template cache dir
    # dbh => DBI->connect(...),       # and your own properties
});
