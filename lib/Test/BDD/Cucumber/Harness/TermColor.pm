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
use Moo;
use Types::Standard qw( Str HashRef FileHandle );

use Getopt::Long;

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

has 'fh' => ( is => 'rw', isa => FileHandle, default => sub { \*STDOUT } );

=head2 theme

Name of the theme to use for colours. Defaults to `dark`. Themes are defined
in the private attribute C<_themes>, and currently include `light` and `dark`

=cut

has theme => (
    'is'    => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $theme = 'dark';
        Getopt::Long::Configure('pass_through');
        GetOptions( "c|theme=s" => \$theme );
        return ($theme);
    }
);

has _themes => (
    is      => 'ro',
    isa     => HashRef[HashRef],
    lazy    => 1,
    default => sub {
        {
            dark => {
                'feature'       => 'bright_white',
                'scenario'      => 'bright_white',
                'scenario_name' => 'bright_blue',
                'pending'       => 'yellow',
                'passing'       => 'green',
                'failed'        => 'red',
                'step_data'     => 'bright_cyan',
            },
            light => {
                'feature'       => 'reset',
                'scenario'      => 'black',
                'scenario_name' => 'blue',
                'pending'       => 'yellow',
                'passing'       => 'green',
                'failed'        => 'red',
                'step_data'     => 'magenta',
            },
        };
    }
);

sub _colors {
    my $self = shift;
    return $self->_themes->{ $self->theme }
      || die( 'Unknown color theme [' . $self->theme . ']' );
}

my $margin = 2;
my $current_feature;

sub feature {
    my ( $self, $feature ) = @_;
    my $fh = $self->fh;

    $current_feature = $feature;
    $self->_display(
        {
            indent => 0,
            color  => $self->_colors->{'feature'},
            text   => $feature->keyword_original . ': ' . ( $feature->name || '' ),
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
    my $text =
      $scenario->keyword_original . ': '
      . color( $self->_colors->{'scenario_name'} )
      . ( $scenario->name || '' );

    $self->_display(
        {
            indent       => 2,
            color        => $self->_colors->{'scenario'},
            text         => $text,
            follow_up    =>
              [ map { $_->content } @{ $scenario->description || [] } ],
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
    my $failed    = 0;

    if ( $status eq 'undefined' || $status eq 'pending' ) {
        $color = $self->_colors->{'pending'};
    } elsif ( $status eq 'passing' ) {
        $color = $self->_colors->{'passing'};
    } else {
        $failed    = 1;
        $color     = $self->_colors->{'failed'};
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
        $failed or return;
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
            highlight    => $self->_colors->{'step_data'},
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
                color  => $self->_colors->{'step_data'},
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
        print $fh ' ' x ( $options->{'indent'} + 4 );
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

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
