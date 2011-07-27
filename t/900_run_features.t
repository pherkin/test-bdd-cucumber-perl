#!perl

use strict;
use warnings;

use File::Slurp;

use Test::More;
use Test::BDD::Parser;
use Test::BDD::Executor;

my $document = Test::BDD::Parser->parse_file(
	't/data/features/basic_parse.feature' );

#use Data::Dumper; die Dumper $document;

__DATA__
my $executor = Test::BDD::Executor->new();

$executor->add_steps();
$executor->execute(
	Test::BDD::Parser->parse(read_file('t/data/features/basic_parse.feature'))
);

