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
my $di = ' ' x 17;

sub feature {
    my ( $self, $feature ) = @_;
    note "${li}Feature: " . $feature->name;
    note "$li$ni" . $_->content for @{ $feature->satisfaction };
    note "";
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    note "$li${ni}Scenario: " . ($scenario->name || '');
}
sub scenario_done { note ""; }

sub step {}

sub step_done {
    my ($self, $context, $result) = @_;

    my $status = $result->result;

    my $step = $context->step;
    my $step_name;

    if ( $context->is_hook )
    {
        $status ne 'undefined' and $status ne 'pending' and $status ne 'passing' or return;
        $step_name = 'In ' . ucfirst( $context->verb ) . ' Hook';
    }
    else
    {
        $step_name = $si . ucfirst($step->verb_original) . ' ' . $context->text;
    }


    if ( $status eq 'undefined' || $status eq 'pending' ) {
        if ( $self->fail_skip ) {
            fail( "No matcher for: $step_name" );
            $self->_note_step_data( $step );
        } else {
            TODO: { todo_skip $step_name, 1 };
            $self->_note_step_data( $step );
        }
    } elsif ( $status eq 'passing' ) {
        pass( $step_name );
        $self->_note_step_data( $step );
    } else {
        fail( $step_name );
        $self->_note_step_data( $step );
        if ( ! $context->is_hook )
        {
            my $step_location = '  in step at ' . $step->line->document->filename . ' line ' . $step->line->number . '.';
            diag( $step_location );
        }
        diag( $result->output );
    }
}

sub _note_step_data {
    my ( $self, $step ) = @_;
    return unless $step;
    my @step_data = @{ $step->data_as_strings };
    return unless @step_data;

    if ( ref( $step->data ) eq 'ARRAY' ) {
        for ( @step_data ) {
            note( $di . $_ );
        }
    } else {
        note $di . '"""';
        for ( @step_data ) {
            note( $di . '  ' . $_ );
        }
        note $di . '"""';
    }
}

sub shutdown { done_testing(); }

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
