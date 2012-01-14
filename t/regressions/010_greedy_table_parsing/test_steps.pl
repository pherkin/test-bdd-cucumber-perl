#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::BDD::Cucumber::StepFile;
use Digest::MD5;
use Method::Signatures;

Given qr/a Digest MD5 object/, func($c) {
    $c->stash->{scenario}{digest} = Digest::MD5->new;
};

When qr/I add "([^"]+)" to the object/, func($c) {
    $c->stash->{scenario}{digest}->add($1);
};

Then qr/the results look like/, func($c) {
	my $data   = $c->data;
	my $digest = $c->stash->{scenario}{digest};
    foreach my $row (@{$data}) {
		my $func   = $row->{method};
		my $expect = $row->{output};
		my $got    = $digest->$func();
        is $got, $expect, "test: $func";
    }
};
