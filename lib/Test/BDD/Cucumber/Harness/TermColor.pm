package Test::BDD::Cucumber::Harness::TermColor;

=head1 NAME

Test::BDD::Cucumber::Harness::TermColor - Prints colorized text to the screen

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass that prints test output, colorized,
to the terminal.

=head1 METHODS

=head2 result

Returns a collective view on the passing status of all steps run so far,
as a L<Test::BDD::Cucumber::Model::Resullt> object.

=cut

use strict;
use warnings;
use Moose;
use Term::ANSIColor;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Model::Result;

extends 'Test::BDD::Cucumber::Harness';

my @results;

sub result {
    my $self = shift;
    return Test::BDD::Cucumber::Model::Result->from_children( @results );
}

my $margin = 2;
if ( $margin > 1 ) {
    print "\n" x ( $margin - 1 );
}

my $current_feature;

sub feature {
    my ( $self, $feature ) = @_;
    $current_feature = $feature;
    $self->_display({
        indent    => 0,
        color     => 'bright_white',
        text      => $feature->name,
        follow_up => [ map { $_->content } @{ $feature->satisfaction || [] } ],
        trailing  => 1
    });
}

sub feature_done { print "\n"; }

sub scenario {
    my ( $self, $scenario, $dataset, $longest ) = @_;
    my $text =
        "Scenario: " . color('bright_blue') . ($scenario->name || '' );

    $self->_display({
        indent    => 2,
        color     => 'bright_white',
        text      => $text,
        follow_up => [],
        trailing  => 0,
        longest_line => ($longest||0)
    });
}

sub scenario_done { print "\n"; }

sub step {}
sub step_done {
    my ($self, $context, $result ) = @_;
    push(@results, $result);

    my $color;
    my $follow_up = [];
    my $status = $result->result;

    if ( $status eq 'undefined' || $status eq 'pending' ) {
        $color = 'yellow';
    } elsif ( $status eq 'passing' ) {
        $color = 'green';
    } else {
        $color = 'red';
        $follow_up = [ split(/\n/, $result->{'output'} ) ];
    }

    $self->_display({
        indent    => 4,
        color     => $color,
        text      => $context->step->verb . ' ' . $context->text,
        highlight => 'bright_cyan',
        trailing  => 0,
        follow_up => $follow_up,
        longest_line => $context->stash->{'scenario'}->{'longest_step_line'}
    });

    $self->_note_step_data( $context->step );
}

sub _note_step_data {
    my ( $self, $step ) = @_;
    my @step_data = @{ $step->data_as_strings };
    return unless @step_data;

    my $note = sub {
        my ( $text, $extra_indent ) = @_;
        $extra_indent ||= 0;

        $self->_display({
            indent   => 6 + $extra_indent,
            color    => 'bright_cyan',
            text      => $text
        });
    };

    if ( ref( $step->data ) eq 'ARRAY' ) {
        for ( @step_data ) {
            $note->( $_ );
        }
    } else {
        $note->('"""');
        for ( @step_data ) {
            $note->( $_, 2 );
        }
        $note->('"""');
    }
}

sub _display {
    my ( $class, $options ) = @_;
    $options->{'indent'} += $margin;

    # Reset it all...
    print color 'reset';

    # Print the main line
    print ' ' x $options->{'indent'};

    # Highlight as appropriate
    my $color = color $options->{'color'};
    if ( $options->{'highlight'} ) {
        my $reset = color 'reset';
        my $base  = color $options->{'color'};
        my $hl    = color $options->{'highlight'};

        my $text = $base . Test::BDD::Cucumber::Util::bs_quote( $options->{'text'} );
        $text =~ s/("(.+?)"|[ ^](\d[-?\d\.]*))/$reset$hl$1$reset$base/g;
        print Test::BDD::Cucumber::Util::bs_unquote( $text );

    # Normal output
    } else {
        print color $options->{'color'};
        print $options->{'text'};
    }

    # Reset and newline
    print color 'reset';
    print "\n";

    # Print follow-up lines...
    for my $line ( @{ $options->{'follow_up'} || [] } ) {
        print color 'reset';
        print ' ' x ( $options->{'indent'} + 2 );
        print color $options->{'color'};
        print $line;
        print color 'reset';
        print "\n";
    }

    print "\n" if $options->{'trailing'};
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;