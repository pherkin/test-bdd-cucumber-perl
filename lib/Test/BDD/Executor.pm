package Test::BDD::Cucumber::Executor;

use Moose;
use FindBin::libs;
use Storable qw(dclone);
use Test::Builder;

use Test::BDD::Cucumber::StepContext;
use Test::BDD::Cucumber::Util;

has 'steps'          => ( is => 'rw', isa => 'HashRef', default => sub {{}} );
has 'executor_stash' => ( is => 'rw', isa => 'HashRef', default => sub {{}} );

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
    my $feature_stash = {};

    $harness->feature( $feature );

    # Execute scenarios
    for my $outline ( @{ $feature->scenarios } ) {

        # Multiply out Scenario Outlines as appropriate
        my @datasets = @{ $outline->data };
        @datasets = ({}) unless @datasets;

        foreach my $dataset ( @datasets ) {
            my $scenario_stash = {};

            # OK, back to the normal execution
            $harness->scenario( $outline, $dataset,
                $scenario_stash->{'longest_step_line'} );

            foreach my $step (@{ $outline->steps }) {
                # Multiply out any placeholders
                my $text = $self->add_placeholders( $step->text, $dataset );

                # Set up a context
                my $context = Test::BDD::Cucumber::StepContext->new({

                    # Data portion
                    data    => ref($step->data) ? dclone($step->data) : $step->data || '',
                    stash   => {
                        feature  => $feature_stash,
                        scenario => $scenario_stash,
                        step     => {},
                    },

                    # Step-specific info
                    feature  => $feature,
                    scenario => $outline,
                    step     => $step,
                    verb     => lc($step->verb),
                    text     => $text,

                    # Communicators
                    harness  => $harness

                });
                $self->dispatch( $context );
            }

            $harness->scenario_done( $outline, $dataset );
        }
    }

    $harness->feature_done( $feature );
}

sub add_placeholders {
    my ( $self, $text, $dataset ) = @_;
    my $quoted_text = Test::BDD::Cucumber::Util::bs_quote( $text );
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die "No mapping to placeholder $1 in: $text"
    /eg;
    return Test::BDD::Cucumber::Util::bs_unquote( $quoted_text );
}

sub dispatch {
    my ( $self, $context ) = @_;

    for my $cmd (
        # Look in the right verb place
        @{ $self->{'steps'}->{$context->verb} || [] },
        # Look in the catch-all verb place
        @{ $self->{'steps'}->{'steps'} || [] },
        # This matches everything and it's our skip step
        [ qr/.?/, sub { $_[0]->stash->{'step'}->{'notfound'} = 1 } ]
    ) {
        my ( $regular_expression, $coderef ) = @$cmd;

        if ( $context->text =~ $regular_expression ) {
            # Setup what we'll pass to step_done, with out localized
            # Test::Builder stuff.
            my $tb_return;
            {
                my $output = '';
                $tb_return = {
                    output => \$output,
                    builder => Test::Builder->create()
                };
                # Set its outputs to be self-referential
                $tb_return->{'builder'}->output( \$output );
                $tb_return->{'builder'}->failure_output( \$output );
                $tb_return->{'builder'}->todo_output( \$output );
                $tb_return->{'builder'}->ok(1, "Starting to execute step");
            }

            # Say we're about to start it up
            $context->harness->step( $context );

            # New scope for the localization
            {
                # Localize test builder
                local $Test::Builder::Test = $tb_return->{'builder'};
                # Guarantee the $<digits> :-/
                $context->matches([ $context->text =~ $regular_expression ]);
                # Execute!
                eval { $coderef->( $context ) };
                if ( $@ ) {
                    $Test::Builder::Test->ok( 0, "Test compiled" );
                    $Test::Builder::Test->diag( $@ );
                }
            }
            # Close up the Test::Builder object
            $tb_return->{'builder'}->done_testing();

            # Close up the harness
            $context->harness->step_done( $context, $tb_return );
            return;
        }
    }
}

sub setup {
    my $self = shift;
    return;
}

1;
