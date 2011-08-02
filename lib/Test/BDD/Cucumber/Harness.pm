package Test::BDD::Cucumber::Harness;

=head1 NAME

Test::BDD::Cucumber::Harness - Base class for creating harnesses

=head1 DESCRIPTION

Harnesses allow your feature files to be executed while telling the outside
world about how the testing is going, and what's being tested. This is a base
class for creating new harnesses. You can see
L<Test::BDD::Cucumber::Harness::TermColor> and
L<Test::BDD::Cucumber::Harness::TestBuilder> for examples.

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

sub feature { my ( $self, $feature ) = @_; }

sub feature_done {
    my ( $self, $feature ) = @_;
}

=head2 scenario

=head2 scenario_done

Called at the start and end of scenario execution respectively. Both methods
accept a L<Test::BDD::Cucmber::Model::Scenario> module and a dataset hash.

=cut

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
}

sub scenario_done {
    my ( $self, $scenario, $dataset ) = @_;
}

=head2 step

=head2 step_done

Called at the start and end of step execution respectively. Both methods
accept a L<Test::BDD::Cucmber::StepConcept> object. C<step_done> also accepts
a hash of data relating to L<Test::Builder> of the structure:

    {
        output => SCALAR REF,
        builder => Test::Builder object
    };

The output is the output of the step as if it had been run as a test script -
useful for providing debugging output when a step has failed. The
L<Test::Builder> is a localized instance just for that step.

=cut

sub step {
    my ( $self, $context ) = @_;
}

sub step_done {
    my ($self, $context, $tb_hash) = @_;

}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;