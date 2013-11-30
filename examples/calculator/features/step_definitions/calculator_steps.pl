#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use Method::Signatures;

use lib 'examples/calculator/lib/';

Before func( $c ) {
    use_ok( 'Calculator' );
};

After func( $c ) {
    # a bit contrived, as garbage collection would clear it out
    delete $c->stash->{'scenario'}->{'Calculator'};
    ok( not exists $c->stash->{'scenario'}->{'Calculator'} );
};

my %numbers_as_words = (
    __THE_NUMBER_ONE__ => 1,
    __THE_NUMBER_FOUR__ => 4,
    __THE_NUMBER_FIVE__ => 5,
    __THE_NUMBER_TEN__ => 10,
);

sub map_word_to_number
{
    my $word = shift;

    ok( $word );
    ok( exists $numbers_as_words{ $word } );
    
    return $numbers_as_words{ $word };
}

Transform qr/^(__THE_NUMBER_\w+__)$/, func( $c ) { map_word_to_number( $1 ) };

Transform qr/^table:number as word$/, func( $c, $data ) {
    for my $row ( @{ $data } )
    {
        $row->{'number'} = map_word_to_number( $row->{'number as word'} );
    }
};

Given 'a new Calculator object', func ($c) {
    $c->stash->{'scenario'}->{'Calculator'} = Calculator->new() };

Given qr/^having pressed (.+)/, func($c) {
    $c->stash->{'scenario'}->{'Calculator'}->press( $_ ) for split(/(,| and) /, $1);
};

Given qr/^having keyed (.+)/, func($c) {
    # Make this call the having pressed
    my ( $value ) = @{ $c->matches };
    $c->stash->{'scenario'}->{'Calculator'}->key_in( $value );
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

Given 'having added these numbers', func ($c) {
    for my $row ( @{ $c->data } )
    {
        $c->stash->{'scenario'}->{'Calculator'}->key_in( $row->{number} );
        $c->stash->{'scenario'}->{'Calculator'}->key_in( '+' );
    }
};

Then qr/^the display should show (.+)/, func($c) {
    my ( $value ) = @{ $c->matches };
    is( $c->stash->{'scenario'}->{'Calculator'}->display, $value,
        "Calculator display as expected" );
};
