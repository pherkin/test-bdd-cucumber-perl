package Test::BDD::Cucumber::Harness::TAP;

=head1 NAME

Test::BDD::Cucumber::Harness::TAP - Generate results in TAP format

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass whose output
is TAP (Test Anything Protocol), such as consumed by C<prove>
and C<yath>.

=head1 OPTIONS

=head2 fail_skip

Boolean - makes tests with no matcher fail

=cut

use strict;
use warnings;
use Moo;

use Types::Standard qw( Bool InstanceOf );
use Test2::API qw/context/;


extends 'Test::BDD::Cucumber::Harness';
has 'fail_skip' => ( is => 'rw', isa => Bool, default => 0 );


sub feature {
    my ( $self, $feature ) = @_;

    my $ctx = context();
    $ctx->note(join('', $feature->keyword_original, ' ',
                    $feature->name, "\n",
                    map { $_->content } @{ $feature->satisfaction }));
    $ctx->release;
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    my $ctx = context();
    $ctx->note(join('', $scenario->keyword_original, ' ',
                    ($scenario->name || ''), "\n",
                    map { $_->content} @{ $scenario->description }));
    $ctx->release;
}
sub scenario_done { }

sub step { }

sub step_done {
    my ( $self, $context, $result ) = @_;

    my $status = $result->result;

    my $step = $context->step;
    my $step_name;

    my $ctx = context();
    if ( $context->is_hook ) {
        $status ne 'undefined'
            and $status ne 'pending'
            and $status ne 'passing'
            or do { $ctx->release; return; };
        $step_name = 'In ' . ucfirst( $context->verb ) . ' Hook';
    } else {
        $step_name
            = 'In ' . ucfirst( $step->verb_original ) . ' ' . $context->text;
    }

    if ( $status eq 'undefined' || $status eq 'pending' ) {
        if ( $self->fail_skip ) {
            if ( $status eq 'undefined' ) {
                $ctx->fail( "No matcher for: $step_name",
                            $self->_note_step_data($step));
            } else {
                $ctx->skip( "Test skipped due to failure in previous step",
                            $self->_note_step_data($step));
            }
        } else {
            $ctx->todo_skip($step_name, 'Step not implemented');
            $ctx->note($self->_note_step_data($step));
        }
    } elsif ( $status eq 'passing' ) {
        $ctx->pass( $step_name );
        $ctx->note($self->_note_step_data($step));
    } else {
        $ctx->fail( $step_name );
        $ctx->note($self->_note_step_data($step));
        if ( !$context->is_hook ) {
            my $step_location
                = '  in step at '
                . $step->line->document->filename
                . ' line '
                . $step->line->number . '.';
            $ctx->diag($step_location);
        }
        $ctx->diag( $result->output );
    }
    $ctx->release;
}

sub _note_step_data {
    my ( $self, $step ) = @_;
    return unless $step;
    my @step_data = @{ $step->data_as_strings };
    return '' unless @step_data;

    if ( ref( $step->data ) eq 'ARRAY' ) {
        return join("\n", @step_data);
    } else {
        return join('', '"""', join("\n", @step_data), '"""');
    }
}

sub shutdown { my $self = shift; my $ctx = context(); $ctx->done_testing; $ctx->release; }

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2020, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
