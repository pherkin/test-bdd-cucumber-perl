package Test::BDD::Cucumber::Extension;

=head1 NAME

Test::BDD::Cucumber::Extension - Abstract superclass for extensions

=head1 DESCRIPTION

Provides an abstract superclass for extensions.  Loaded extensions will
have their hook-implementations triggered at specific points during
the BDD script execution.

=cut

use Moose;
use namespace::autoclean;

=head1 PROPERTIES


=head2 config

A hash, the configuration read from the config file, verbatim.  Extensions
should look for their own configuration in
  $self->config->{extensions}->{<extension>}

=cut

has config => ( is => 'rw', isa => 'HashRef' );

=head1 METHODS

=head2 steps_directories()

The returns an arrayref whose values enumerate directories (relative to
the directory of the extension) which hold step files to be loaded when
the extension is loaded.

=cut

sub step_directories { return []; }

=head2 pre_feature($feature, $feature_stash)

Invoked by the Executor before executing the background and feature scenarios
and their respective pre-hooks. Reports errors by calling croak().

=head2 post_feature($feature, $feature_stash)

Invoked by the Executor after executing the background and feature scenarios
and their repective post-hooks. Reports errors by calling croak().

=cut

sub pre_feature  { return; }
sub post_feature { return; }

=head2 pre_scenario($scenario, $feature_stash, $scenario_stash)

Invoked by the Executor before executing the steps in $scenario and
their respective pre-hooks. Reports errors by calling croak().

=head2 post_scenario($scenario, $feature_stash, $scenario_stash, $failed)

Invoked by the Executor after executing all the steps in $scenario
and their repective post-hooks. Reports errors by calling croak().

$failure indicates whether any of the steps in the scenario has failed.

=cut

sub pre_scenario  { return; }
sub post_scenario { return; }

=head2 pre_step($step, $step_context)

Invoked by the Executor before executing each step in $scenario.
Reports errors by calling croak().

Feature and scenario stashes can be reached through
 $step_context->{stash}->{feature} and 
 $step_context->{stash}->{scenario}

Note: *executed* steps, so not called for skipped steps.

=head2 post_scenario($step, $step_context, $failed)

Invoked by the Executor after each executed step in $scenario.
Reports errors by calling croak().

$failure indicates whether the step has failed.

Note: *executed* steps, so not called for skipped steps.

=cut

sub pre_step  { return; }
sub post_step { return; }

=head1 AUTHOR

Erik Huelsmann C<ehuels@gmail.com>

=head1 LICENSE

Copyright 2016, Erik Huelsmann; Licensed under the same terms as Perl

=cut

__PACKAGE__->meta->make_immutable;

1;
