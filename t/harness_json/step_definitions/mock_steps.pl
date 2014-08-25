#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

Given qr/we have list of items="([^"]*)"/ => sub {
    S->{items} = [ split /,\s*/, $1 ];
};

When 'calculate count' => sub {
    S->{count} = scalar @{ S->{items} };
};

Then qr/number of items is "([^"]*)"/ => sub {
    is( S->{count}, $1 );
};

Given qr/that we receive list of items from server/ => sub {
    local $TODO = "mock TODO message";
    ok(0);
};
