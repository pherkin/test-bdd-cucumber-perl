#!perl

use strict;
use warnings;
use Test::More;
use Test::BDD::Cucumber::StepFile;
use Test::Builder;

# Test global builder used in some Test::* packages
my $Tester;
sub get_tester {
    return $Tester //= Test::Builder->new();
}

sub is_odd {
    my ($number) = @_;
    get_tester()->ok($number % 2, "Number $number is odd");
}

sub is_even {
    my ($number) = @_;
    get_tester()->ok(!($number % 2), "Number $number is even");
}

Step qr/the number (\d+) is odd/ => sub {
    is_odd($1);
};

Step qr/the number (\d+) is even/ => sub {
    is_even($1);
};
