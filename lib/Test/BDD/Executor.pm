package Test::BDD::Executor;

use strict;
use warnings;
use FindBin::libs;
use Storable qw(dclone);

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

    # Map the steps to be lower case...
    for ( @steps ) {
        my ( $verb, $match, $code ) = @$_;
        $verb = lc $verb;
        unless (ref( $match )) {
            $match =~ s/:\s*$//;
            $match = quotemeta( $match );
            $match = qr/^$match:?/i;
        }

        push( @{ $self->{'steps'}->{$verb} }, [ $match, $code ] );
    }
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
            print '  Scenario: ' . ($outline->name||'') . "\n";
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

    for my $cmd ( @{ $self->{'steps'}->{lc($step->verb)} || [] } ) {
        my ( $regular_expression, $coderef ) = @$cmd;

        # Doing this twice is no fun
        my @matches = $text =~ $regular_expression;
        if ( $text =~ $regular_expression ) {
            $matched++;

            # Build a context
            die "THIS SHOULD BE BUILT FURTHER UP AND PASSED IN TO DISPATCH";
            my $context = Test::BDD::StepContext->new({
                # Data portion
                matches => \@matches,
                data    => dclone($step->data),
                stash   => {
                    feature  => {},
                    scenario => {}
                    step     => {},
                },

                # Step-specific info
                feature  => $feature,
                scenario => $scenario,
                step     => $step,
                text     => $text,

                # Communicator
                harness  => $harness,
            });
            $context->harness->execute_step( $context );

            $coderef->( $context );
        }
    }

    warn "Can't find a match for [" . $step->verb . "]: $text" unless $matched;
}

sub setup {
    my $self = shift;
    return;
}

1;
