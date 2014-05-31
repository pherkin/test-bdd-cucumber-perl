#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

use lib 'examples/calculator/lib/';

Before sub {
    use_ok( 'Calculator' );
};

After sub {
    my $c = shift;
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

Transform qr/^(__THE_NUMBER_\w+__)$/, sub { map_word_to_number( $1 ) };

Transform qr/^table:number as word$/, sub {
    my ( $c, $data ) = @_;

    for my $row ( @{ $data } ) {
        $row->{'number'} = map_word_to_number( $row->{'number as word'} );
    }
};

Given 'a new Calculator object', sub {
    S->{'Calculator'} = Calculator->new()
};

Given qr/^having pressed (.+)/, sub {
    S->{'Calculator'}->press( $_ ) for split(/(,| and) /, $1);
};

Given qr/^having keyed (.+)/, sub {
    # Make this call the having pressed
    my ( $value ) = @{ C->matches };
    S->{'Calculator'}->key_in( $value );
};

Given 'having successfully performed the following calculations', sub {
    my $calculator = S->{'Calculator'};

    for my $row ( @{ C->data } ) {
        $calculator->key_in( $row->{'first'}    );
        $calculator->key_in( $row->{'operator'} );
        $calculator->key_in( $row->{'second'}   );
        $calculator->press( '=' );

        is( $calculator->display,
            $row->{'result'},
            $row->{'first'} .' '. $row->{'operator'} .' '. $row->{'second'} );
    }
};

Given 'having entered the following sequence', sub {
    S->{'Calculator'}->key_in( C->data );
};

Given 'having added these numbers', sub {
    for my $row ( @{ C->data } )
    {
        S->{'Calculator'}->key_in( $row->{number} );
        S->{'Calculator'}->key_in( '+' );
    }
};

Then qr/^the display should show (.+)/, sub {
    my ( $value ) = @{ C->matches };
    is( S->{'Calculator'}->display, $value,
        "Calculator display as expected" );
};
