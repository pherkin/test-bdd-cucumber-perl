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
use List::Util qw/first/;
use Test::Builder;

use Test::BDD::Cucumber::StepContext;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Model::Result;

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

has 'steps' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub add_steps {
    my ( $self, @steps ) = @_;

    # Map the steps to be lower case...
    for (@steps) {
        my ( $verb, $match, $code ) = @$_;
        $verb = lc $verb;

        if ( $verb =~ /^(before|after)$/ ) {
            $code  = $match;
            $match = qr//;
        } else {
            unless ( ref($match) ) {
                $match =~ s/:\s*$//;
                $match = quotemeta($match);
                $match = qr/^$match:?/i;
            }
        }

        if ( $verb eq 'transform' or $verb eq 'after' ) {

            # Most recently defined Transform takes precedence
            # and After blocks need to be run in reverse order
            unshift( @{ $self->{'steps'}->{$verb} }, [ $match, $code ] );
        } else {
            push( @{ $self->{'steps'}->{$verb} }, [ $match, $code ] );
        }

    }
}

=head2 execute

Execute accepts a feature object, a harness object, and an optional
L<Test::BDD::Cucumber::TagSpec> object and for each scenario in the
feature which meets the tag requirements (or all of them, if you
haven't specified one), runs C<execute_scenario>.

=cut

sub execute {
    my ( $self, $feature, $harness, $tag_spec ) = @_;
    my $feature_stash = {};

    $harness->feature($feature);
    my @background =
      ( $feature->background ? ( background => $feature->background ) : () );

    # Get all scenarios
    my @scenarios = @{ $feature->scenarios() };

    # Filter them by the tag spec, if we have one
    if ( defined $tag_spec ) {
        @scenarios = $tag_spec->filter(@scenarios);
    }

    for my $scenario (@scenarios) {

        # Execute the scenario itself
        $self->execute_scenario(
            {
                @background,
                scenario      => $scenario,
                feature       => $feature,
                feature_stash => $feature_stash,
                harness       => $harness
            }
        );
    }

    $harness->feature_done($feature);
}

=head2 execute_scenario

Accepts a hashref of options, and executes each step in a scenario. Options:

C<feature> - A L<Test::BDD::Cucumber::Model::Feature> object

C<feature_stash> - A hashref that should live the lifetime of feature execution

C<harness> - A L<Test::BDD::Cucumber::Harness> subclass object

C<scenario> - A L<Test::BDD::Cucumber::Model::Scenario> object

C<background_obj> - An optional L<Test::BDD::Cucumber::Model::Scenario> object
representing the Background

C<scenario_stash> - We'll create a new scenario stash unless you've posted one
in. This is used exclusively for giving Background sections access to the same
stash as the scenario they're running before.

For each step, a L<Test::BDD::Cucumber::StepContext> object is created, and
passed to C<dispatch()>. Nothing is returned - everything is played back through
the Harness interface.

=cut

sub execute_scenario {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background_obj,
        $incoming_scenario_stash, $incoming_outline_stash )
      = @$options{
        qw/ feature feature_stash harness scenario background scenario_stash
          outline_stash
          /
      };

    my $is_background = $outline->background;

    my $harness_start = $is_background ? 'background'      : 'scenario';
    my $harness_stop  = $is_background ? 'background_done' : 'scenario_done';

    my $outline_stash = $incoming_outline_stash || { short_circuit => 0 };

    # Multiply out Scenario Outlines as appropriate
    my @datasets = @{ $outline->data };
    @datasets = ( {} ) unless @datasets;

    my $scenario_stash = $incoming_scenario_stash || {};

    my %context_defaults = (

        # Data portion
        data  => '',
        stash => {
            feature => $feature_stash,
            step    => {},
        },

        # Step-specific info
        feature  => $feature,
        scenario => $outline,

        # Communicators
        harness => $harness,

        transformers => $self->{'steps'}->{'transform'} || [],
    );

    foreach my $dataset (@datasets) {
        my $scenario_stash = $incoming_scenario_stash || {};
        $context_defaults{stash}->{scenario} = $scenario_stash;

        # OK, back to the normal execution
        $harness->$harness_start( $outline, $dataset,
            $scenario_stash->{'longest_step_line'} );

        if ( not $is_background ) {
            for my $before_step ( @{ $self->{'steps'}->{'before'} || [] } ) {

                # Set up a context
                my $context = Test::BDD::Cucumber::StepContext->new(
                    {
                        %context_defaults, verb => 'before',
                    }
                );

                my $result =
                  $self->dispatch( $context, $before_step,
                    $outline_stash->{'short_circuit'} );

                # If it didn't pass, short-circuit the rest
                unless ( $result->result eq 'passing' ) {
                    $outline_stash->{'short_circuit'}++;
                }
            }
        }

        # Run the background if we have one. This recurses back in to
        # execute_scenario...
        if ($background_obj) {
            $self->execute_scenario(
                {
                    is_background  => 1,
                    scenario       => $background_obj,
                    feature        => $feature,
                    feature_stash  => $feature_stash,
                    harness        => $harness,
                    scenario_stash => $scenario_stash,
                    outline_stash  => $outline_stash
                }
            );
        }

        foreach my $step ( @{ $outline->steps } ) {

            # Multiply out any placeholders
            my $text = $self->add_placeholders( $step->text, $dataset );

            # Set up a context
            my $context = Test::BDD::Cucumber::StepContext->new(
                {
                    %context_defaults,

                    # Data portion
                    columns => $step->columns || [],
                    data => ref( $step->data )
                    ? dclone( $step->data )
                    : $step->data || '',

                    # Step-specific info
                    step => $step,
                    verb => lc( $step->verb ),
                    text => $text,
                }
            );

            my $result =
              $self->find_and_dispatch( $context,
                $outline_stash->{'short_circuit'} );

            # If it didn't pass, short-circuit the rest
            unless ( $result->result eq 'passing' ) {
                $outline_stash->{'short_circuit'}++;
            }

        }

        if ( not $is_background ) {
            for my $after_step ( @{ $self->{'steps'}->{'after'} || [] } ) {

                # Set up a context
                my $context = Test::BDD::Cucumber::StepContext->new(
                    {
                        %context_defaults, verb => 'after',
                    }
                );

                # All After steps should happen, to ensure cleanup
                my $result = $self->dispatch( $context, $after_step, 0 );
            }
        }

        $harness->$harness_stop( $outline, $dataset );
    }

    return;
}

=head2 add_placeholders

Accepts a text string and a hashref, and replaces C< <placeholders> > with the
values in the hashref, returning a string.

=cut

sub add_placeholders {
    my ( $self, $text, $dataset ) = @_;
    my $quoted_text = Test::BDD::Cucumber::Util::bs_quote($text);
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die "No mapping to placeholder $1 in: $text"
    /eg;
    return Test::BDD::Cucumber::Util::bs_unquote($quoted_text);
}

=head2 find_and_dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and searches through
the steps that have been added to the executor object, executing against the
first matching one.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped.

=cut

sub find_and_dispatch {
    my ( $self, $context, $short_circuit ) = @_;

    # Short-circuit if we need to
    return $self->skip_step( $context, 'pending',
        "Short-circuited from previous tests" )
      if $short_circuit;

    # Try and find a matching step
    my $step = first { $context->text =~ $_->[0] }
    @{ $self->{'steps'}->{ $context->verb } || [] },
      @{ $self->{'steps'}->{'step'} || [] };

    # Deal with the simple case of no-match first of all
    return $self->skip_step( $context, 'undefined',
            "No matching step definition for: "
          . $context->verb . ' '
          . $context->text )
      unless $step;

    return $self->dispatch( $context, $step, 0 );
}

=head2 dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and a L<Test::BDD::Cucumber::Step>
object and executes it.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped.

=cut

sub dispatch {
    my ( $self, $context, $step, $short_circuit ) = @_;

    return $self->skip_step( $context, 'pending',
        "Short-circuited from previous tests" )
      if $short_circuit;

    # Execute the step definition
    my ( $regular_expression, $coderef ) = @$step;

    # Setup what we'll pass to step_done, with out localized Test::Builder stuff
    my $output    = '';
    my $tb_return = {
        output  => \$output,
        builder => Test::Builder->create()
    };

    # Set its outputs to be self-referential
    $tb_return->{'builder'}->output( \$output );
    $tb_return->{'builder'}->failure_output( \$output );
    $tb_return->{'builder'}->todo_output( \$output );

    # Make a minumum pass
    $tb_return->{'builder'}
      ->ok( 1, "Starting to execute step: " . $context->text );

    # Say we're about to start it up
    $context->harness->step($context);

    # New scope for the localization
    my $result;
    {
        # Localize test builder
        local $Test::Builder::Test = $tb_return->{'builder'};

        # Guarantee the $<digits> :-/
        $context->matches( [ $context->text =~ $regular_expression ] );

        # Execute!
        eval {
            no warnings 'redefine';
            local *Test::BDD::Cucumber::StepFile::S = sub {
                return $context->stash->{'scenario'};
            };
            local *Test::BDD::Cucumber::StepFile::C = sub {
                return $context;
            };
            $coderef->($context);
        };
        if ($@) {
            $Test::Builder::Test->ok( 0, "Test compiled" );
            $Test::Builder::Test->diag($@);
        }

        # Close up the Test::Builder object
        $tb_return->{'builder'}->done_testing();

        my $status = $self->_test_status( $tb_return->{builder} );

        # Create the result object
        $result = Test::BDD::Cucumber::Model::Result->new(
            {
                result => $status,
                output => $output
            }
        );

    }

    # Say the step is done, and return the result. Happens outside
    # the above block so that we don't have the localized harness
    # anymore...
    $context->harness->add_result($result);
    $context->harness->step_done( $context, $result );
    return $result;
}

sub _test_status {
    my $self    = shift;
    my $builder = shift;

    my $results =
        $builder->can("history")
      ? $self->_test_status_from_history($builder)
      : $self->_test_status_from_details($builder);

    # Turn that in to a Result status
    return
        $results->{'fail'} ? 'failing'
      : $results->{'todo'} ? 'pending'
      :                      'passing';
}

sub _test_status_from_details {
    my $self    = shift;
    my $builder = shift;

    # Make a note of test status
    my %results = map {
        if ( $_->{'ok'} ) {
            if ( $_->{'type'} eq 'todo' || $_->{'type'} eq 'todo_skip' ) {
                ( todo => 1 );
            } else {
                ( pass => 1 );
            }
        } else {
            ( fail => 1 );
        }
    } $builder->details;

    return \%results;
}

sub _test_status_from_history {
    my $self    = shift;
    my $builder = shift;

    my $history = $builder->history;

    my %results;
    $results{todo} = $history->todo_count ? 1 : 0;
    $results{fail} = !$history->test_was_successful;
    $results{pass} = $history->pass_count ? 1 : 0;

    return \%results;
}

=head2 skip_step

Accepts a step-context, a result-type, and a textual reason, exercises the
Harness's step start and step_done methods, and returns a skipped-test result.

=cut

sub skip_step {
    my ( $self, $context, $type, $reason ) = @_;

    # Pretend to start step execution
    $context->harness->step($context);

    # Create a result object
    my $result = Test::BDD::Cucumber::Model::Result->new(
        {
            result => $type,
            output => '1..0 # SKIP ' . $reason
        }
    );

    # Pretend we executed it
    $context->harness->add_result($result);
    $context->harness->step_done( $context, $result );
    return $result;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
