use v5.14;
use warnings;

package Test::BDD::Cucumber::Model::Result;

=head1 NAME

Test::BDD::Cucumber::Model::Result - Encapsulates a result state

=head1 DESCRIPTION

Encapsulation of result state - whether that's for a step, scenario, or feature

=cut

use Moo;
use Types::Standard qw( Enum Str );

=head1 ATTRIBUTES

=head2 result

Enum of: C<passing>, C<failing>, C<pending> or C<undefined>. C<pending> is used
if there was any TODO output from a test, and C<undefined> for a test that
wasn't run, either due to no matching step, or because a previous step failed.

=cut

has 'result' => ( is => 'ro', isa => Enum[qw( passing failing pending undefined )], required => 1 );

=head2 output

The underlying test-output that contributed to a result.

=cut

has 'output' => ( is => 'ro', isa => Str, required => 1 );

=head1 METHODS

=head2 from_children

Collates the Result objects you pass in, and returns one that encompasses all
of them.

As they may be varied, it runs through them in order of C<failing>,
C<undefined>, C<pending> and C<passing> - the first it finds is the overall
result. The empty set passes.

=cut

sub from_children {
    my ( $class, @children ) = @_;

    # We'll be looking for the presence of just one of any of the
    # short-circuiting statuses, but we need to keep a sum of all the output.
    # Passing is the default state, so we cheat and say there was one of them.
    my %results = ( passing => 1 );
    my $output;

    for my $child (@children) {

        # Save the status of that child
        $results{ $child->result }++;

        # Add its output
        $output .= $child->output . "\n";
    }
    $output .= "\n";

    for my $status (qw( failing undefined pending passing )) {
        if ( $results{$status} ) {
            return $class->new(
                {
                    result => $status,
                    output => $output
                }
            );
        }
    }
}

1;
