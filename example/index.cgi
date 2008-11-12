#! /usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use NanoA;

NanoA::Dispatch->dispatch({
    prefix => 'MyApp',
});
