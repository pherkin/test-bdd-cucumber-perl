#!perl

use strict;
use warnings;

use Digest;
use Test::More;

use Test::BDD::Cucumber::StepFile;

Given qr/a usable "(\w+)" class/, sub { use_ok( C->matches->[0] ); };

Given qr/a Digest (\S+) object/, sub {
    my $object = Digest->new( C->matches->[0] );
    ok( $object, "Object created" );
    S->{'object'} = $object;
};

When qr/I've added "(.+)" to the object/, sub {
    S->{'object'}->add( C->matches->[0] );
};

When "I've added the following to the object", sub {
    S->{'object'}->add( C->data );
};

Then qr/the (.+) output is "(.+)"/, sub {
    my ( $type, $expected ) = @{ C->matches };
    my $method = {
        'base64' => 'b64digest',
        'hex' => 'hexdigest'
    }->{ $type };

    is( S->{'object'}->$method, $expected );
};
