package Test::BDD::Cucumber::Model::Result;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

enum 'StepStatus', [qw( passing failing pending undefined )];

has 'result' => ( is => 'ro', isa => 'StepStatus', required => 1 );
has 'output' => ( is => 'ro', isa => 'Str',        required => 1 );

sub from_children {
	my ( $class, @children ) = @_;

	# We'll be looking for the presence of just one of any of the
	# short-circuiting statuses, but we need to keep a sum of all the output.
	# Passing is the default state, so we cheat and say there was one of them.
	my %results = ( passing => 1 );
	my $output;

	for my $child ( @children ) {
		# Save the status of that child
		$results{ $child->result }++;
		# Add its output
		$output .= $child->output . "\n"
	}
	$output .= "\n";

	for my $status ( qw( failing undefined pending passing ) ) {
		if ( $results{$status} ) {
			return $class->new({
				result => $status,
				output => $output
			});
		}
	}
}

1;