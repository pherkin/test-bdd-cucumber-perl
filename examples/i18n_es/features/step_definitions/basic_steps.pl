#!perl
 
use strict;
use warnings;

use Digest;

use Test::More;
use Test::BDD::Cucumber::StepFile;
 
Dado qr/la clase "(\w+)"/, sub {
	use_ok( C->matches->[0] );
};

Dado qr/un objeto Digest usando el algoritmo "(\S+)"/, sub {
   my $object = Digest->new( C->matches->[0] );
   ok( $object, "Objecto creado" );
   S->{'object'} = $object;
};

Cuando qr/he agregado "(\w+)" al objeto/, sub {
   S->{'object'}->add( C->matches->[0] );
};
 
Cuando "he agregado los siguientes datos al objeto", sub {
   S->{'object'}->add( C->data );
};

Entonces qr/el resultado (?:en\s*)?(\w+) es "(.+)"/, sub {
    my ( $type, $expected ) = @{ C->matches };
    my $method = {
        'base64' 		=>	'b64digest',
        'hexadecimal'	=>	'hexdigest'
    }->{$type};

    is( S->{'object'}->$method(), $expected );
};
