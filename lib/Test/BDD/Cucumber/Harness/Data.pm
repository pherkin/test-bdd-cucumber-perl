package Test::BDD::Cucumber::Harness::Data;

=head1 NAME

Test::BDD::Cucumber::Harness::Data - Builds up an internal data representation
of test passes / failures

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass which collates test data in C<data>.

=cut

use strict;
use warnings;
use Moose;
use Test::More;
use Test::BDD::Cucumber::Model::Result;

extends 'Test::BDD::Cucumber::Harness';
has 'features' => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} );
has 'current_feature'  => ( is => 'rw', isa => 'HashRef', default => sub {{}} );
has 'current_scenario' => ( is => 'rw', isa => 'HashRef', default => sub {{}} );
has 'current_step'     => ( is => 'rw', isa => 'HashRef', default => sub {{}} );

# We will keep track of where we are each time...
sub feature {
	my ( $self, $feature ) = @_;
	my $feature_ref = {
		object    => $feature,
		scenarios => []
	};
	$self->current_feature( $feature_ref );
}
sub feature_done {
	my $self = shift;
	push( @{ $self->features }, $self->current_feature );
	$self->current_feature({});
}

sub scenario {
	my ( $self, $scenario, $dataset ) = @_;
	my $scenario_ref = {
		object  => $scenario,
		dataset => $dataset,
		steps   => [],
	};
	$self->current_scenario( $scenario_ref );
}
sub scenario_done {
	my $self = shift;
	push( @{ $self->current_feature->{'scenarios'} }, $self->current_scenario );
	$self->current_scenario({});
}

sub step {
	my ( $self, $step_context ) = @_;
	my $step_ref = {
		context => $step_context
	};
	$self->current_step( $step_ref );
}

sub step_done {
    my ($self, $context, $result) = @_;

    $self->current_step->{'result'} = $result;
    push( @{ $self->current_scenario->{'steps'} }, $self->current_step );
    $self->current_step({});
}

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
	my ($self, $step) = @_;
	return $step->{'result'};
}

# Find a step
sub find_scenario_step_by_name {
	my ( $self, $scenario, $name ) = @_;
	my ( $step ) = grep {
		$_->{'context'}->text eq $name
	} @{ $scenario->{'steps'} };

	return $step;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
