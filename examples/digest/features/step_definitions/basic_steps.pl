#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use Method::Signatures;

Given qr/a usable "(\w+)" class/, func ($c) { use_ok( $1 ); };
Given qr/a Digest (\S+) object/, func ($c) {
    my $object = Digest->new($1);
    ok( $object, "Object created" );
    $c->stash->{'scenario'}->{'object'} = $object;
};

When qr/I've added "(.+)" to the object/, func ($c) {
    $c->stash->{'scenario'}->{'object'}->add( $1 );
};

When "I've added the following to the object", func ($c) {
    $c->stash->{'scenario'}->{'object'}->add( $c->data );
};

Then qr/the (.+) output is "(.+)"/, func ($c) {
    my $method = {base64 => 'b64digest', 'hex' => 'hexdigest' }->{ $1 } ||
        do { fail("Unknown output type $1"); return };
    is( $c->stash->{'scenario'}->{'object'}->$method, $2 );
};