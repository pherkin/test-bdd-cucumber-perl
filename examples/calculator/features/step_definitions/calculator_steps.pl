#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::StepFile;
use Method::Signatures;

use Calculator;

Given qr/^a usable "(\w+)" class/, func($c) { use_ok( $1 ) };

Given 'a new Calculator object', func ($c) {
    $c->stash->{'scenario'}->{'Calculator'} = Calculator->new() };

Given qr/^having pressed (.+)/, func($c) {
    $c->stash->{'scenario'}->{'Calculator'}->press( $_ ) for split(/ and /, $1);
};

Given qr/^having keyed (.+)/, func($c) {
    $c->stash->{'scenario'}->{'Calculator'}->press( $_ ) for split(//, $1);
};


Then qr/^the display should show (.+)/, func($c) {
    is( $c->stash->{'scenario'}->{'Calculator'}->display, $1,
        "Calculator display as expected" );
};
