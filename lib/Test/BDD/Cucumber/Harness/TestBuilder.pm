package Test::BDD::Cucumber::Harness::TestBuilder;

use strict;
use warnings;
use Moose;
use Test::More;

extends 'Test::BDD::Cucumber::Harness';

my $li = ' ' x 7;
my $ni = ' ' x 4;
my $si = ' ' x 9;

sub feature {
    my ( $self, $feature ) = @_;
    note "${li}Feature: " . $feature->name;
    note "$li$ni" . $_->content for @{ $feature->satisfaction };
    note "";
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    if ( $scenario->background ) {
        note "$li${ni}Background:";
    } else {
        note "$li${ni}Scenario: " . ($scenario->name || '');
    }
}
sub scenario_done { note ""; }

sub step_done {
    my ($self, $context, $tb_hash) = @_;
    my $step_name = "$si" . ucfirst($context->step->verb_original) .
        ' ' . $context->text;

    my $output = ${ $tb_hash->{'output'} };
    ok( $tb_hash->{'builder'}->is_passing, $step_name ) ||
        diag( $output );
}

1;