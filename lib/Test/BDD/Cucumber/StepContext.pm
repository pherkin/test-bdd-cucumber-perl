package Test::BDD::Cucumber::StepContext;
use Moose;

=head1 NAME

Test::BDD::Cucumber::StepContext - Data made available to step definitions

=head1 DESCRIPTION

The coderefs in Step Definitions have a single argument passed to them, a
C<Test::BDD::Cucumber::StepContext> object. This is an attribute-only class,
populated by L<Test::BDD::Cucumber::Executor>.

=head1 ATTRIBUTES

=head2 data

Step-specific data. Will either be a text string in the case of a """ string, or
an arrayref of hashrefs if the step had an associated table.

=cut

has 'data'     => ( is => 'ro' );

=head2 stash

A hash of hashes, containing three keys, C<feature>, C<scenario> and C<step>.
The stash allows you to persist data across features, scenarios, or steps
(although the latter is there for completeness, rather than having any useful
function).

=cut

has 'stash'    => ( is => 'ro', required => 1, isa => 'HashRef' );

=head2 feature

=head2 scenario

=head2 step

Links to the L<Test::BDD::Cucumber::Model::Feature>,
L<Test::BDD::Cucumber::Model::Scenario>, and L<Test::BDD::Cucumber::Model::Step>
objects respectively.

=cut

has 'feature'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Feature' );
has 'scenario' => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Scenario' );
has 'step'     => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Step' );

=head2 verb

The lower-cased verb a Step Definition was called with.

=cut

has 'verb'     => ( is => 'ro', required => 1, isa => 'Str' );

=head2 text

The text of the step, minus the verb. Placeholders will have already been
multiplied out at this point.

=cut

has 'text'     => ( is => 'ro', required => 1, isa => 'Str' );

=head2 harness

The L<Test::BDD::Cucumber::Harness> harness being used by the executor.

=cut

has 'harness'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Harness' );

=head2 matches

Any matches caught by the Step Definition's regex. These are also available as
C<$1>, C<$2> etc as appropriate.

=cut

has 'matches'  => ( is => 'rw', isa => 'ArrayRef' );

=head1 METHODS

=head2 background

Boolean for "is this step being run as part of the background section?".
Currently implemented by asking the linked Scenario object...

=cut

sub background { my $self = shift; return $self->scenario->background }

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
