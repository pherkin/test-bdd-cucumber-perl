package Test::BDD::Cucumber::Harness::TermColor;

=head1 NAME

Test::BDD::Cucumber::Harness::TermColor - Prints colorized text to the screen

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass that prints test output, colorized,
to the terminal.

=head1 CONFIGURABLE ENV

=head2 ANSI_COLORS_DISABLED

You can use L<Term::ANSIColor>'s C<ANSI_COLORS_DISABLED> to turn off colors
in the output.

=cut

use strict;
use warnings;
use Moose;

# Try and make the colors just work on Windows...
BEGIN {
    if (
        # We're apparently on Windows
        $^O =~ /MSWin32/i &&

        # We haven't disabled coloured output for Term::ANSIColor
        ( !$ENV{'ANSI_COLORS_DISABLED'} ) &&

        # Here's a flag you can use if you really really need to turn this fall-
        # back behaviour off
        ( !$ENV{'DISABLE_WIN32_FALLBACK'} )
      )
    {
        # Try and load
        eval { require Win32::Console::ANSI };
        if ($@) {
            print "# Install Win32::Console::ANSI to display colors properly\n";
        }
    }
}

use Term::ANSIColor;
use Test::BDD::Cucumber::Model::Result;

extends 'Test::BDD::Cucumber::Harness';

=head1 CONFIGURABLE ATTRIBUTES

=head2 fh

A filehandle to write output to; defaults to C<STDOUT>

=cut

has 'fh' => ( is => 'rw', isa => 'FileHandle', default => sub { \*STDOUT } );

my $margin = 2;

sub BUILD {
    my $self = shift;
    my $fh   = $self->fh;

    if ( $margin > 1 ) {
        print $fh "\n" x ( $margin - 1 );
    }
}

my $current_feature;

sub feature {
    my ( $self, $feature ) = @_;
    my $fh = $self->fh;

    $current_feature = $feature;
    $self->_display(
        {
            indent => 0,
            color  => 'bright_white',
            text   => $feature->name,
            follow_up =>
              [ map { $_->content } @{ $feature->satisfaction || [] } ],
            trailing => 1
        }
    );
}

sub feature_done {
    my $self = shift;
    my $fh   = $self->fh;
    print $fh "\n";
}

sub scenario {
    my ( $self, $scenario, $dataset, $longest ) = @_;
    my $text = "Scenario: " . color('bright_blue') . ( $scenario->name || '' );

    $self->_display(
        {
            indent       => 2,
            color        => 'bright_white',
            text         => $text,
            follow_up    => [],
            trailing     => 0,
            longest_line => ( $longest || 0 )
        }
    );
}

sub scenario_done {
    my $self = shift;
    my $fh   = $self->fh;
    print $fh "\n";
}

sub step { }

sub step_done {
    my ( $self, $context, $result, $highlights ) = @_;

    my $color;
    my $follow_up = [];
    my $status    = $result->result;

    if ( $status eq 'undefined' || $status eq 'pending' ) {
        $color = 'yellow';
    } elsif ( $status eq 'passing' ) {
        $color = 'green';
    } else {
        $color = 'red';
        $follow_up = [ split( /\n/, $result->{'output'} ) ];

        if ( !$context->is_hook ) {
            unshift @{$follow_up},
                'step defined at '
              . $context->step->line->document->filename
              . ' line '
              . $context->step->line->number . '.';
        }
    }

    my $text;

    if ( $context->is_hook ) {
        $color eq 'red' or return;
        $text = 'In ' . ucfirst( $context->verb ) . ' Hook';
        undef $highlights;
    } elsif ($highlights) {
        $text = $context->step->verb_original . ' ' . $context->text;
        $highlights =
          [ [ 0, $context->step->verb_original . ' ' ], @$highlights ];
    } else {
        $text = $context->step->verb_original . ' ' . $context->text;
        $highlights = [ [ 0, $text ] ];
    }

    $self->_display(
        {
            indent       => 4,
            color        => $color,
            text         => $text,
            highlights   => $highlights,
            highlight    => 'bright_cyan',
            trailing     => 0,
            follow_up    => $follow_up,
            longest_line => $context->stash->{'scenario'}->{'longest_step_line'}
        }
    );

    $self->_note_step_data( $context->step );
}

sub _note_step_data {
    my ( $self, $step ) = @_;
    return unless $step;
    my @step_data = @{ $step->data_as_strings };
    return unless @step_data;

    my $note = sub {
        my ( $text, $extra_indent ) = @_;
        $extra_indent ||= 0;

        $self->_display(
            {
                indent => 6 + $extra_indent,
                color  => 'bright_cyan',
                text   => $text
            }
        );
    };

    if ( ref( $step->data ) eq 'ARRAY' ) {
        for (@step_data) {
            $note->($_);
        }
    } else {
        $note->('"""');
        for (@step_data) {
            $note->( $_, 2 );
        }
        $note->('"""');
    }
}

sub _display {
    my ( $class, $options ) = @_;
    my $fh = ref $class ? $class->fh : \*STDOUT;
    $options->{'indent'} += $margin;

    # Reset it all...
    print $fh color 'reset';

    # Print the main line
    print $fh ' ' x $options->{'indent'};

    # Highlight as appropriate
    my $color = color $options->{'color'};
    if ( $options->{'highlight'} && $options->{'highlights'} ) {
        my $reset = color 'reset';
        my $base  = color $options->{'color'};
        my $hl    = color $options->{'highlight'};

        for ( @{ $options->{'highlights'} } ) {
            my ( $flag, $text ) = @$_;
            print $fh $reset . ( $flag ? $hl : $base ) . $text . $reset;
        }

        # Normal output
    } else {
        print $fh color $options->{'color'};
        print $fh $options->{'text'};
    }

    # Reset and newline
    print $fh color 'reset';
    print $fh "\n";

    # Print follow-up lines...
    for my $line ( @{ $options->{'follow_up'} || [] } ) {
        print $fh color 'reset';
        print $fh ' ' x ( $options->{'indent'} + 2 );
        print $fh color $options->{'color'};
        print $fh $line;
        print $fh color 'reset';
        print $fh "\n";
    }

    print $fh "\n" if $options->{'trailing'};
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
