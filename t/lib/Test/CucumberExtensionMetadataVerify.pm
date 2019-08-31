#!perl

package Test::CucumberExtensionMetadataVerify;

# Extension to verify existence of metadata

use Moo;
use Carp;
use Scalar::Util qw( reftype );

use Test::BDD::Cucumber::Extension;
extends 'Test::BDD::Cucumber::Extension';


sub pre_step  {
    my ($self, $step, $step_context) = @_;

    croak 'pre_step called with incorrect number $step array elements'
        if scalar(@$step) != 3;

    croak 'pre_step called with incorrect first element type of $step array'
        # 5.10 reports SCALAR where the argument actually is a regexp; ignore <=5.10
        if reftype $step->[0] ne 'REGEXP' and $] ge '5.012';

    croak 'pre_step called with incorrect second element type of $step array'
        if reftype $step->[1] ne 'HASH';

    croak 'pre_step called with incorrect meta data content in $step array'
        if exists $step->[1]->{meta} and $step->[1]->{meta} ne 'data';

    croak 'pre_step called with incorrect third element type of $step array'
        if reftype $step->[2] ne 'CODE';
}

__PACKAGE__->meta->make_immutable;

1;
