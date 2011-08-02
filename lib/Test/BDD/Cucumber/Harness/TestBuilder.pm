package Test::BDD::Cucumber::Harness::TestBuilder;

=head1 NAME

Test::BDD::Cucumber::Harness::TestBuilder - Pipes step output via Test::Builder

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass whose output is sent to
L<Test::Builder>.

=cut

use strict;
use warnings;
use Moose;
use Test::More;

extends 'Test::BDD::Cucumber::Harness';
has 'fail_skip' => ( is => 'rw', isa => 'Bool', default => 0 );

my $li = ' ' x 7;
my $ni = ' ' x 4;
my $si = ' ' x 9;

sub feature {
    my ( $self, $feature ) = @_;
    note "${li}Feature: " . $feature->name;
    note "$li$ni" . $_->content for @{ $feature->satisfaction };
    note "";
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    if ( $scenario->background ) {
        note "$li${ni}Background:";
    } else {
        note "$li${ni}Scenario: " . ($scenario->name || '');
    }
}
sub scenario_done { note ""; }

sub step_done {
    my ($self, $context, $tb_hash) = @_;

    my $step_name = $si . ucfirst($context->step->verb_original) . ' ' .
        $context->text;

    if ( $context->stash->{'step'}->{'notfound'} ) {
        if ( $self->fail_skip ) {
            fail( "No matcher for: $step_name" );
        } else {
            TODO: { todo_skip $step_name, 1 };
        }
    } elsif ( $tb_hash->{'builder'}->is_passing ) {
        pass( $step_name );
    } else {
        fail( $step_name );
        diag( ${$tb_hash->{'output'}} );
    }
}

1;