package Test::BDD::Cucumber::Harness;

=head1 NAME

Test::BDD::Cucumber::Harness - Base class for creating harnesses

=head1 DESCRIPTION

Harnesses allow your feature files to be executed while telling the outside
world about how the testing is going, and what's being tested. This is a base
class for creating new harnesses. You can see
L<Test::BDD::Cucumber::Harness::TermColor> and
L<Test::BDD::Cucumber::Harness::TestBuilder> for examples, although if you need
to interact with the results in a more exciting way, you'd be best off
interacting with L<Test::BDD::Cucumber::Harness::Data>.

=head1 METHODS / EVENTS

=cut

use strict;
use warnings;
use Moose;

=head2 feature

=head2 feature_done

Called at the start and end of feature execution respectively. Both methods
accept a single argument of a L<Test::BDD::Cucumber::Model::Feature>.

=cut

sub feature      { my ( $self, $feature ) = @_; }
sub feature_done { my ( $self, $feature ) = @_; }

=head2 background

=head2 background_done

If you have a background section, then we execute it as a quasi-scenario step
before each scenario. These hooks are fired before and after that, and passed
in the L<Test::BDD::Cucmber::Model::Scenario> that represents the Background
section, and a a dataset hash (although why would you use that?)

=cut

sub background      { my ( $self, $scenario, $dataset ) = @_; }
sub background_done { my ( $self, $scenario, $dataset ) = @_; }

=head2 scenario

=head2 scenario_done

Called at the start and end of scenario execution respectively. Both methods
accept a L<Test::BDD::Cucmber::Model::Scenario> module and a dataset hash.

=cut

sub scenario      { my ( $self, $scenario, $dataset ) = @_; }
sub scenario_done { my ( $self, $scenario, $dataset ) = @_; }

=head2 step

=head2 step_done

Called at the start and end of step execution respectively. Both methods
accept a L<Test::BDD::Cucmber::StepConcept> object. C<step_done> also accepts
a L<Test::BDD::Cucumber::Model::Result> object.

=cut

sub step      { my ( $self, $context ) = @_; }
sub step_done { my ($self, $context, $result) = @_; }

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;