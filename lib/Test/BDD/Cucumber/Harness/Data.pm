package Test::BDD::Cucumber::Harness::Data;

=head1 NAME

Test::BDD::Cucumber::Harness::Data - Builds up an internal data representation of test passes / failures

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass which collates test data

=cut

use strict;
use warnings;
use Moo;
use Types::Standard qw( HashRef ArrayRef );
use Test::More;
use Test::BDD::Cucumber::Model::Result;

extends 'Test::BDD::Cucumber::Harness';

=head1 ATTRIBUTES

=head2 features

An array-ref in which we store all the features executed, and completed. Until
C<feature_done> is called, it won't be in here.

=cut

has 'features' => ( is => 'rw', isa => ArrayRef, default => sub { [] } );

=head2 current_feature

=head2 current_scenario

=head2 current_step

The current feature/step/scenario for which we've had the starting method, but
not the C<_done> method.

=cut

has 'current_feature' =>
  ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'current_scenario' =>
  ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'current_step' => ( is => 'rw', isa => HashRef, default => sub { {} } );

=head2 feature

=head2 feature_done

Feature hashref looks like:

 {
	object    => Test::BDD::Cucumber::Model::Feature object
	scenarios => []
 }

=cut

# We will keep track of where we are each time...
sub feature {
    my ( $self, $feature ) = @_;
    my $feature_ref = {
        object    => $feature,
        scenarios => []
    };
    $self->current_feature($feature_ref);
}

sub feature_done {
    my $self = shift;
    push( @{ $self->features }, $self->current_feature );
    $self->current_feature( {} );
}

=head2 scenario

=head2 scenario_done

Scenario hashref looks like:

 {
	object  => Test::BDD::Cucumber::Model::Scenario object
	dataset => Data hash the scenario was invoked with
	steps   => [],
 }

=cut

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    my $scenario_ref = {
        object  => $scenario,
        dataset => $dataset,
        steps   => [],
    };
    $self->current_scenario($scenario_ref);
}

sub scenario_done {
    my $self = shift;
    push( @{ $self->current_feature->{'scenarios'} }, $self->current_scenario );
    $self->current_scenario( {} );
}

=head2 step

=head2 step_done

Step hashref looks like:

 {
 	context => Test::BDD::Cucumber::StepContext object
 	result  => Test::BDD::Cucumber::Model::Result object (after step_done)
 }

=cut

sub step {
    my ( $self, $step_context ) = @_;
    my $step_ref = { context => $step_context };
    $self->current_step($step_ref);
}

sub step_done {
    my ( $self, $context, $result, $highlights ) = @_;

    $self->current_step->{'result'}     = $result;
    $self->current_step->{'highlights'} = $highlights;
    push( @{ $self->current_scenario->{'steps'} }, $self->current_step );
    $self->current_step( {} );
}

=head2 feature_status

=head2 scenario_status

=head2 step_status

Accepting one of the data-hashes above, returns a
L<Test::BDD::Cucumber::Model::Result> object representing it. If it's a Feature
or a Scenario, then it returns one representing all the child objects.

=cut

# Status methods
sub feature_status {
    my ( $self, $feature ) = @_;
    return Test::BDD::Cucumber::Model::Result->from_children(
        map { $self->scenario_status($_) } @{ $feature->{'scenarios'} } );
}

sub scenario_status {
    my ( $self, $scenario ) = @_;
    return Test::BDD::Cucumber::Model::Result->from_children(
        map { $self->step_status($_) } @{ $scenario->{'steps'} } );
}

sub step_status {
    my ( $self, $step ) = @_;
    return $step->{'result'};
}

=head2 find_scenario_step_by_name

Given a Scenario and a string, searches through the steps for it and returns
the data-hash where the Step Object's C<<->text>> matches the string.

=cut

# Find a step
sub find_scenario_step_by_name {
    my ( $self, $scenario, $name ) = @_;
    my ($step) =
      grep { $_->{'context'}->text eq $name } @{ $scenario->{'steps'} };

    return $step;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
