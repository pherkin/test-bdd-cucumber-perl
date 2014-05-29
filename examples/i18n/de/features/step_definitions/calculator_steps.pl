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
    # a bit contrived, as garbage collection would clear it out
    delete S->{'Calculator'};
    ok( not exists S->{'Calculator'} );
};

my %numbers_as_words = (
    __THE_NUMBER_ONE__  => 1,
    __THE_NUMBER_FOUR__ => 4,
    __THE_NUMBER_FIVE__ => 5,
    __THE_NUMBER_TEN__  => 10,
);

sub map_word_to_number {
    my $word = shift;

    ok( $word );
    ok( exists $numbers_as_words{ $word } );
    
    return $numbers_as_words{ $word };
}

Transform qr/^(__THE_NUMBER_\w+__)$/, sub { map_word_to_number( $1 ) };

Transform qr/^table:number as word$/, sub {
    my ($c, $data)=@_;

    for my $row ( @{ $data } ) {
        $row->{'number'} = map_word_to_number( $row->{'number as word'} );
    }
};

Gegebensei 'ein neues Objekt der Klasse Calculator', sub {
    S->{'Calculator'} = Calculator->new()
};

Wenn qr/^ich (.+) gedrückt habe/, sub {
    S->{'Calculator'}->press( $_ ) for split(/(,| und) /, $1);
};

Wenn qr/^die Tasten (.+) gedrückt wurden/, sub {
    # Make this call the having pressed
    my ( $value ) = @{ C->matches };
    S->{'Calculator'}->key_in( $value );
};

Wenn 'ich erfolgreich folgende Rechnungen durchgeführt habe', sub {
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

Wenn 'ich folgende Zeichenfolge eingegeben habe', sub {
    S->{'Calculator'}->key_in( C->data );
};

Wenn 'ich folgende Zahlen addiert habe', sub {
    for my $row ( @{ C->data } ) {
        S->{'Calculator'}->key_in( $row->{number} );
        S->{'Calculator'}->key_in( '+' );
    }
};

Dann qr/^ist auf der Anzeige (.+) zu sehen/, sub {
    my ( $value ) = @{ C->matches };
    is( S->{'Calculator'}->display, $value,
        "Calculator display as expected" );
};
