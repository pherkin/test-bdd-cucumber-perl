package Test::BDD::Harness;

use strict;
use warnings;
use Moose;

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

my $last_step;

sub step {
    my ( $self, $context ) = @_;
    print '    ' . ucfirst($context->step->verb_original) . ' ' . $context->text;
}

sub step_done {
    my ($self, $tb_hash) = @_;
    my $output = ${ $tb_hash->{'output'} };
    if ( $tb_hash->{'builder'}->is_passing ) {
        print "\t\t[OK]\n";
    } else {
        print "\t\t[FAIL]\n----------\n$output----------\n";
    }
}

1;