package Test::BDD::Cucumber::Executor;

=head1 NAME

Test::BDD::Cucumber::Executor - Run through Feature and Harness objects

=head1 DESCRIPTION

The Executor runs through Features, matching up the Step Lines with Step
Definitions, and reporting on progress through the passed-in harness.

=cut

use Moose;
use FindBin::libs;
use Storable qw(dclone);
use Test::Builder;

use Test::BDD::Cucumber::StepContext;
use Test::BDD::Cucumber::Util;

=head1 METHODS

=head2 steps

=head2 add_steps

The attributes C<steps> is a hashref of arrayrefs, storing steps by their Verb.
C<add_steps()> takes step definitions of the item list form:

 (
  [ Given => qr//, sub {} ],
 ),

and populates C<steps> with them.

=cut

has 'steps'          => ( is => 'rw', isa => 'HashRef', default => sub {{}} );

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

=head2 execute

Execute accepts a feature and a harness object, and creates
L<Test::BDD::Cucumber::StepContext> for each step in each scenario, passing them on to
C<dispatch()>

=cut

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

=head2 add_place_holders

Accepts a text string and a hashref, and replaces C< <placeholders> > with the
values in the hashref, returning a string.

=cut

sub add_placeholders {
    my ( $self, $text, $dataset ) = @_;
    my $quoted_text = Test::BDD::Cucumber::Util::bs_quote( $text );
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die "No mapping to placeholder $1 in: $text"
    /eg;
    return Test::BDD::Cucumber::Util::bs_unquote( $quoted_text );
}

=head2 dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and searches through
the steps that have been added to the executor object, executing against the
first matching one.

=cut

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

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
