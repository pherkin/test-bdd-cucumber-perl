package Test::BDD::Cucumber::Harness::TermColor;

=head1 NAME

Test::BDD::Cucumber::Harness::TermColor - Prints colorized text to the screen

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass that prints test output, colorized,
to the terminal.

=head1 METHODS

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
        eval "require Win32::Console::ANSI";
        if ($@) {
            print "# Install Win32::Console::ANSI to display colors properly\n";
        }
    }
}

use Term::ANSIColor;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Model::Result;

extends 'Test::BDD::Cucumber::Harness';

my $margin = 2;
if ( $margin > 1 ) {
    print "\n" x ( $margin - 1 );
}

my $current_feature;

sub feature {
    my ( $self, $feature ) = @_;
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

sub feature_done { print "\n"; }

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

sub scenario_done { print "\n"; }

sub step { }

sub step_done {
    my ( $self, $context, $result ) = @_;

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
    } else {
        $text = $context->step->verb_original . ' ' . $context->text;
    }

    $self->_display(
        {
            indent       => 4,
            color        => $color,
            text         => $text,
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

        my $text =
          $base . Test::BDD::Cucumber::Util::bs_quote( $options->{'text'} );
        $text =~ s/("(.+?)"|[ ^](\d[-?\d\.]*))/$reset$hl$1$reset$base/g;
        print Test::BDD::Cucumber::Util::bs_unquote($text);

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
