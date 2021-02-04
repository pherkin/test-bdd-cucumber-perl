#!perl

use strict;
use warnings;

use Test::More;

my $dir = 'examples';
my @examples = grep { -d $_ } glob("$dir/*");
#diag explain \@examples;

for my $example (@examples) {
    my $exit = system "$^X -Ilib bin/pherkin $example";
    is $exit, 0, "exit code of $example";
}

done_testing;
