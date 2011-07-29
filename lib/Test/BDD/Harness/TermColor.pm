package Test::BDD::Harness::TermColor;

use strict;
use warnings;
use Moose;
use Term::ANSIColor;
use Test::BDD::Util;

extends 'Test::BDD::Harness';

my $margin = 2;
if ( $margin > 1 ) {
    print "\n" x ( $margin - 1 );
}

sub feature {
    my ( $self, $feature ) = @_;
    $self->display({
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
    my $text = $scenario->background ?
        "Background:" :
        "Scenario: " . color('bright_blue') . ($scenario->name || '' );

    $self->display({
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
    my ($self, $context, $tb_hash) = @_;

    my $color;
    my $follow_up = [];

    if ( $context->stash->{'step'}->{'notfound'} ) {
        $color = 'yellow';
    } elsif ( $tb_hash->{'builder'}->is_passing ) {
        $color = 'green';
    } else {
        $color = 'red';
        $follow_up = [ split(/\n/, ${ $tb_hash->{'output'} } ) ];

    }

    $self->display({
        indent    => 4,
        color     => $color,
        text      => $context->step->verb . ' ' . $context->text,
        highlight => 'bright_cyan',
        trailing  => 0,
        follow_up => $follow_up,
        longest_line => $context->stash->{'scenario'}->{'longest_step_line'}
    });
}

sub display {
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

        my $text = $base . Test::BDD::Util::bs_quote( $options->{'text'} );
        $text =~ s/("(.+?)"|[ ^](\d[-?\d\.]*))/$reset$hl$1$reset$base/g;
        print Test::BDD::Util::bs_unquote( $text );

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

1;