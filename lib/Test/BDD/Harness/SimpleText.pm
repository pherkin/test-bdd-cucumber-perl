package Test::BDD::Harness::SimpleText;

use strict;
use warnings;
use Moose;

extends 'Test::BDD::Harness';

sub feature {
    my ( $self, $feature ) = @_;
    print "Feature: " . $feature->name . "\n";
}
sub feature_done { print "\n\n"; }

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    print $scenario->background ? "  Background:\n" :
        "  Scenario: " . ($scenario->name || '') . "\n"
}

sub scenario_done { print "\n"; }

sub step {
    my ( $self, $context ) = @_;
    print '    ' . ucfirst($context->step->verb_original) . ' ' . $context->text;
}

sub step_done {
    my ($self, $context, $tb_hash) = @_;
    my $output = ${ $tb_hash->{'output'} };
    if ( $context->stash->{'step'}->{'notfound'} ) {
        print ".. [TODO]\n";
    } elsif ( $tb_hash->{'builder'}->is_passing ) {
        print " .. [OK]\n";
    } else {
        print " .. [FAIL]\n----------\n$output----------\n";
    }
}

1;