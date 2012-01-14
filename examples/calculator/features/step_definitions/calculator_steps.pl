#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use Method::Signatures;

use lib 'examples/calculator/lib/';
use Calculator;

Given qr/^a usable "(\w+)" class/, func($c) { use_ok( $1 ) };

Given 'a new Calculator object', func ($c) {
    $c->stash->{'scenario'}->{'Calculator'} = Calculator->new() };

Given qr/^having pressed (.+)/, func($c) {
    $c->stash->{'scenario'}->{'Calculator'}->press( $_ ) for split(/(,| and) /, $1);
};

Given qr/^having keyed (.+)/, func($c) {
    # Make this call the having pressed
    $c->stash->{'scenario'}->{'Calculator'}->key_in( $1 );
};

Given 'having successfully performed the following calculations', func ($c) {
    my $calculator = $c->stash->{'scenario'}->{'Calculator'};

    for my $row ( @{ $c->data } ) {
        $calculator->key_in( $row->{'first'}    );
        $calculator->key_in( $row->{'operator'} );
        $calculator->key_in( $row->{'second'}   );
        $calculator->press( '=' );

        is( $calculator->display,
            $row->{'result'},
            $row->{'first'} .' '. $row->{'operator'} .' '. $row->{'second'} );
    }
};

Given 'having entered the following sequence', func ($c) {
    $c->stash->{'scenario'}->{'Calculator'}->key_in( $c->data );
};

Then qr/^the display should show (.+)/, func($c) {
    is( $c->stash->{'scenario'}->{'Calculator'}->display, $1,
        "Calculator display as expected" );
};
