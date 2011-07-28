package Test::BDD::Executor;

use strict;
use warnings;
use FindBin::libs;

use Test::BDD::Util;

sub new {
    my $class = shift();
    bless {
        executor_stash => {},
        steps          => {}
    }, $class;
}

sub add_steps {
    my ( $self, @steps ) = @_;
#    push( @{ $self->{'steps'} }, @steps );
}

sub execute {
    my ( $self, $feature, $harness ) = @_;
    my $stash = {};

    # Display feature attributes
    print 'Feature: ' . $feature->name . "\n";

    # Execute scenarios
    for my $outline ( @{ $feature->scenarios } ) {

        # Multiply out Scenario Outlines as appropriate
        my @datasets = @{ $outline->data };
        @datasets = ({}) unless @datasets;

        foreach my $dataset ( @datasets ) {
            print '  Scenario: ' . $outline->name . "\n";
            foreach my $step (@{ $outline->steps }) {
                # Multiply out any placeholders
                my $text = $self->add_placeholders( $step->text, $dataset );
                print '    ' . $step->verb . ' ' . $text . "\n";
                $self->dispatch( $text, $step, $stash );
            }
        }
    }
}

sub add_placeholders {
    my ( $self, $text, $dataset ) = @_;
    my $quoted_text = Test::BDD::Util::bs_quote( $text );
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die "No mapping to placeholder $1 in: $text"
    /eg;
    return Test::BDD::Util::bs_unquote( $text );
}

sub dispatch {
    my ( $self, $text, $step, $stash ) = @_;
    my $matched;

    for my $cmd ( @{ $self->{'steps'}->{$step->verb} || [] } ) {
        my ( $regular_expression, $coderef ) = @$cmd;

        if ( my @matches = $text =~ $regular_expression ) {
            $matched++;
            $coderef->({
                stash => $stash,
                text  => $text,
                step  => $step
            });
        }
    }

    warn "Can't find a match for [" . $step->verb . "]: $text" unless $matched;
}

sub setup {
    my $self = shift;
    return;
}

1;
