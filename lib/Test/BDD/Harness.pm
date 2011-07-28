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
    print '    ' . ucfirst($context->verb) . ' ' . $context->text;
    $last_step = bless {}, 'Test::BDD::Harness::Step';
    return $last_step;
}
sub step_done {
    my $self = shift;
    if ( $last_step->{'failed'} ) {
        print "   [FAILED] ";
    }
    print "\n";
}

package Test::BDD::Harness::Step;

sub pass {}
sub fail { $_[0]->{'failed'}++ }
sub diag { my ($self, $msg) = @_; print "      ** $msg\n"; }

1;