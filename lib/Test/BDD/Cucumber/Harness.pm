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

has 'results' => ( is => 'ro', default => sub { [] }, isa => 'ArrayRef' );

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
accept a L<Test::BDD::Cucmber::StepContext> object. C<step_done> also accepts
a L<Test::BDD::Cucumber::Model::Result> object and an arrayref of arrayrefs with
locations of consolidated matches, for highlighting.

 [ [2,5], [7,9] ]

=cut

sub step { my ( $self, $context ) = @_; }
sub step_done { my ( $self, $context, $result ) = @_; }

=head2 sub_step

=head2 sub_step_done

As per C<step> and C<step_done>, but for steps that have been called from other
steps. None of the included harnesses respond to these methods, because
generally the whole thing should be transparent, and the parent step handles
passes, failures, etc.

=cut

sub sub_step { my ( $self, $context ) = @_; }
sub sub_step_done { my ( $self, $context, $result ) = @_; }

=head2 startup

=head2 shutdown

Some tests will run one feature, some will run many. For this reason, you may
have harnesses that have something they need to do on start (print an HTML
header), that they shouldn't do at the start of every feature, or a close-down
task (like running C<done_testing()>), that again shouldn't happen on I<every>
feature close-out, just the last.

Just C<$self> as the single argument for both.

=cut

sub startup  { my $self = shift; }
sub shutdown { my $self = shift; }

=head2 add_result

Called before C<step_done> with the step's result. Expected to silently add the
result in to a pool that facilitate the C<result> method. No need to override
this behaviour.

=head2 result

Returns a collective view on the passing status of all steps run so far,
as a L<Test::BDD::Cucumber::Model::Result> object. Default implementation should
be fine for all your needs.

=cut

sub add_result {
    my $self = shift;
    push( @{ $self->results }, shift() );
}

sub result {
    my $self = shift;
    return Test::BDD::Cucumber::Model::Result->from_children(
        @{ $self->results } );
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
