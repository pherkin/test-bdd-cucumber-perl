use v5.14;
use warnings;

package Test::BDD::Cucumber::Extension;

=head1 NAME

Test::BDD::Cucumber::Extension - Abstract superclass for extensions

=head1 DESCRIPTION

Provides an abstract superclass for extensions.  Loaded extensions will
have their hook-implementations triggered at specific points during
the BDD script execution.

=cut

use Moo;
use Types::Standard qw( HashRef );

=head1 PROPERTIES


=head2 config

A hash, the configuration read from the config file, verbatim.  Extensions
should look for their own configuration in
  $self->config->{extensions}->{<extension>}

=cut

has config => ( is => 'rw', isa => HashRef );

=head1 METHODS

=head2 steps_directories()

The returns an arrayref whose values enumerate directories (relative to
the directory of the extension) which hold step files to be loaded when
the extension is loaded.

=cut

sub step_directories { return []; }

=head2 pre_execute($app)

Invoked by C<App::pherkin> before executing any features.  This callback
allows generic extension setup. Reports errors by calling croak(). It is
called once per C<App::pherkin> instance.

Note that the C<TAP::Parser::SourceHandler::Feature> plugin for C<prove>
might instantiate multiple C<App::pherkin> objects, meaning it will create
multiple instances of the extensions too. As such, this callback may be
called once per instance, but multiple times in a Perl image.

The source handler C<fork>s the running Perl instance in order to support
the parallel testing C<-j> option. This callback will be called pre-fork.

=head2 post_execute()

Invoked by C<App::pherkin> after executing all features.  This callback
allows generic extension teardown and cleanup. Reports errors by calling
croak().

Note: When the C<TAP::Parser::SourceHandler::Feature> plugin for C<prove>
 is used, there are no guarantees at this point that this hook is called
 only once.

=cut

sub pre_execute  { return; }
sub post_execute { return; }

=head2 pre_feature($feature, $feature_stash)

Invoked by the Executor before executing the background and feature scenarios
and their respective pre-hooks. Reports errors by calling croak().

=head2 post_feature($feature, $feature_stash)

Invoked by the Executor after executing the background and feature scenarios
and their respective post-hooks. Reports errors by calling croak().

=cut

sub pre_feature  { return; }
sub post_feature { return; }

=head2 pre_scenario($scenario, $feature_stash, $scenario_stash)

Invoked by the Executor before executing the steps in $scenario and
their respective pre-hooks. Reports errors by calling croak().

=head2 post_scenario($scenario, $feature_stash, $scenario_stash, $failed)

Invoked by the Executor after executing all the steps in $scenario
and their respective post-hooks. Reports errors by calling croak().

$failure indicates whether any of the steps in the scenario has failed.

=cut

sub pre_scenario  { return; }
sub post_scenario { return; }

=head2 pre_step($stepdef, $step_context)

Invoked by the Executor before executing each step in $scenario.
Reports errors by calling croak().

C<$stepdef> contains a reference to an array with step data:

  [ qr//, { meta => $data }, $code ]

Feature and scenario stashes can be reached through

  $step_context->stash->{feature}
  # and
  $step_context->stash->{scenario}

Feature, scenario and step (from the feature file) are available as

  $step_context->feature
  $step_context->scenario
  $step_context->step

Note: B<executed> steps, so not called for skipped steps.

=head2 post_step($stepdef, $step_context, $failed, $result)

Invoked by the Executor after each executed step in $scenario.
Reports errors by calling croak().

$failed indicates that the step has not been completed successfully;
this means the step can have failed, be marked as TODO or pending
(not implemented).

$result is a C<Test::BDD::Cucumber::Model::Result> instance which
holds the completion status of the step.

Note: B<executed> steps, so not called for skipped steps.

=cut

sub pre_step  { return; }
sub post_step { return; }

=head1 AUTHOR

Erik Huelsmann C<ehuels@gmail.com>

=head1 LICENSE

  Copyright 2016-2023, Erik Huelsmann; Licensed under the same terms as Perl

=cut

1;
