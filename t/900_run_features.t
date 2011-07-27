#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Parser;
use Test::BDD::Executor;

my $executor = Test::BDD::Executor->new();

$executor->add_steps();
$executor->execute();

