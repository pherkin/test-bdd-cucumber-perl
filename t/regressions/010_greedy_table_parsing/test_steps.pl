#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::BDD::Cucumber::StepFile;
use Digest::MD5;

Given qr/a Digest MD5 object/, sub {
    S->{digest} = Digest::MD5->new;
};

When qr/I add "([^"]+)" to the object/, sub {
    S->{digest}->add( C->matches->[0] );
};

Then qr/the results look like/, sub {
    my $data   = C->data;
    my $digest = S->{digest};
    foreach my $row ( @{$data} ) {
        my $func   = $row->{method};
        my $expect = $row->{output};
        my $got    = $digest->$func();
        is $got, $expect, "test: $func";
    }
};
