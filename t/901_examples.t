#!perl

use strict;
use warnings;

use Test::More;

my $dir = 'examples';
opendir my $dh, $dir or die;
my @examples = grep { $_ ne '.' and $_ ne '..' and -d "$dir/$_" } readdir $dh;
close $dh;
#diag explain \@examples;

for my $example (@examples) {
    my $path_to_example = "$dir/$example";
    my $exit = system "$^X -Ilib bin/pherkin $path_to_example";
    is $exit, 0, "exit code of $example";
}

done_testing;
