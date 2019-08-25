package Test::BDD::Cucumber::Executor;

=head1 NAME

Test::BDD::Cucumber::Executor - Run through Feature and Harness objects

=head1 DESCRIPTION

The Executor runs through Features, matching up the Step Lines with Step
Definitions, and reporting on progress through the passed-in harness.

=cut

use Moo;
use MooX::HandlesVia;
use Types::Standard qw( Bool ArrayRef HashRef );
use Clone qw(clone);
use List::Util qw/first/;
use List::MoreUtils qw/pairwise/;
use Module::Runtime qw/use_module/;
use Number::Range;
use Carp qw/croak/;
our @CARP_NOT;

use Test::Builder;

# Setup wrapping for Test::Builder
use Test::BDD::Cucumber::TestBuilderDelegator;
use Devel::Refcount qw/refcount/;
if ( ( !$ENV{'TEST_BDD_CUCUMBER_NO_TB_WRAP_TEST'} )
    && refcount($Test::Builder::Test) > 1 )
{

    my $ref_trace = "[Install Devel::FindRef to see these diagnostics]";
    if ( eval { use_module "Devel::FindRef" } ) {
        $ref_trace = Devel::FindRef::track($Test::Builder::Test);
    }

    my $message = sprintf( <<'END', $ref_trace );
!!! HEY YOU !!!
Test::BDD::Cucumber needs to be able to wrap $Test::Builder::Test in order to
properly capture testing output. However, something else has already taken a
reference to that module. You need to `use` Test::BDD::Cucumber::Executor
before the other testing modules are used. Modules that appear to already have a
reference are:
-----
%s
-----
You can safetly ignore the global $Test::Builder::Test. In almost all cases, the
simple fix is the move the line that says `use Test::BDD::Cucumber::Executor`
above all other `use Test::*` lines. You can also suppress this check by setting:

  TEST_BDD_CUCUMBER_NO_TB_WRAP_TEST=1
END

    croak $message;
}

$Test::Builder::Test =
  Test::BDD::Cucumber::TestBuilderDelegator->new( Test::Builder->new() );

use Test::BDD::Cucumber::StepContext;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Model::Result;
use Test::BDD::Cucumber::Errors qw/parse_error_from_line/;

has '_bail_out' => ( is => 'rw', isa => Bool, default => 0 );

=head1 METHODS

=head2 extensions

=head2 add_extensions

The attributes C<extensions> is an arrayref of
L<Test::BDD::Cucumber::Extension> extensions. Extensions have their
hook-functions called by the Executor at specific points in the BDD feature
execution.

B<C<<add_extensions>> adds items in FIFO using unshift()>, and are called in
reverse order at the end hook; this means that if you:

  add_extensions( 1 );
  add_extensions( 2, 3 );

The C<pre_*> will be called in order 2, 3, 1, and C<post_*> will be called in
1, 3, 2.

=cut

has extensions => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    handles_via => 'Array',
    handles => { add_extensions => 'unshift' },
);

=head2 steps

=head2 add_steps

The attributes C<steps> is a hashref of arrayrefs, storing steps by their Verb.
C<add_steps()> takes step definitions of the item list form:

 (
  [ Given => qr//, sub {} ],
 ),

Or, when metadata is specified with the step, of the form:

 (
  [ Given => qr//, { meta => $data }, sub {} ]
 ),

(where the hashref stores step metadata) and populates C<steps> with them.

=cut

has 'steps' => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub add_steps {
    my ( $self, @steps ) = @_;

    # Map the steps to be lower case...
    for (@steps) {
        my ( $verb, $match, $meta, $code );

        if (@$_ == 3) {
            ( $verb, $match, $code ) = @$_;
            $meta = {};
        }
        else {
            ( $verb, $match, $meta, $code ) = @$_;
        }
        $verb = lc $verb;

        unless ( ref($match) ) {
            $match =~ s/:\s*$//;
            $match = quotemeta($match);
            $match = qr/^$match:?/i;
        }

        if ( $verb eq 'transform' or $verb eq 'after' ) {

            # Most recently defined Transform takes precedence
            # and After blocks need to be run in reverse order
            unshift( @{ $self->{'steps'}->{$verb} }, [ $match, $meta, $code ] );
        } else {
            push( @{ $self->{'steps'}->{$verb} }, [ $match, $meta, $code ] );
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

    $_->pre_feature( $feature, $feature_stash ) for @{ $self->extensions };
    for my $outline (@scenarios) {

        # Execute the scenario itself
        $self->execute_outline(
            {
                @background,
                scenario      => $outline,
                feature       => $feature,
                feature_stash => $feature_stash,
                harness       => $harness
            }
        );
    }
    $_->post_feature( $feature, $feature_stash, 'no' )
      for reverse @{ $self->extensions };

    $harness->feature_done($feature);
}

=head2 execute_outline

Accepts a hashref of options and executes each scenario definition in the
scenario outline, or, lacking an outline, executes the single defined
scenario.

Options:

C< feature > - A L<Test::BDD::Cucumber::Model::Feature> object

C< feature_stash > - A hashref that should live the lifetime of
 feature execution

C< harness > - A L<Test::BDD::Cucumber::Harness> subclass object

C< outline > - A L<Test::BDD::Cucumber::Model::Scenario> object

C< background > - An optional L<Test::BDD::Cucumber::Model::Scenario> object
representing the Background

=cut

sub execute_outline {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background )
      = @$options{qw/ feature feature_stash harness scenario background /};

    # Multiply out Scenario Outlines as appropriate
    my @datasets = @{ $outline->data };
    @datasets = ( {} ) unless @datasets;

    my $outline_state = {};

    foreach my $dataset (@datasets) {
        $self->execute_scenario(
            {
                feature => $feature,
                feature_stash => $feature_stash,
                harness => $harness,
                scenario => $outline,
                background => $background,
                scenario_stash => {},
                outline_state => $outline_state,
                dataset => $dataset,
            });

        $outline_state->{'short_circuit'} ||= $self->_bail_out;
    }
}

=head2 execute_scenario

Accepts a hashref of options, and executes each step in a scenario. Options:

C<feature> - A L<Test::BDD::Cucumber::Model::Feature> object

C<feature_stash> - A hashref that should live the lifetime of feature execution

C<harness> - A L<Test::BDD::Cucumber::Harness> subclass object

C<scenario> - A L<Test::BDD::Cucumber::Model::Scenario> object

C<background_obj> - An optional L<Test::BDD::Cucumber::Model::Scenario> object
representing the Background

C<scenario_stash> - A hashref that lives the lifetime of the scenario execution

For each step, a L<Test::BDD::Cucumber::StepContext> object is created, and
passed to C<dispatch()>. Nothing is returned - everything is played back through
the Harness interface.

=cut


sub _execute_steps {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline,
        $scenario_stash, $outline_state, $dataset, $context_defaults )
      = @$options{
        qw/ feature feature_stash harness scenario scenario_stash
          outline_state dataset context_defaults
          /
      };


    foreach my $step ( @{ $outline->steps } ) {

        # Multiply out any placeholders
        my $text =
            $self->add_placeholders( $step->text, $dataset, $step->line );
        my $data = $step->data;
        $data = (ref $data) ?
            $self->add_table_placeholders( $data, $dataset, $step->line )
            : (defined $data) ?
            $self->add_placeholders( $data, $dataset, $step->line )
            : '';

        # Set up a context
        my $context = Test::BDD::Cucumber::StepContext->new(
            {
                %$context_defaults,

                    # Data portion
                    columns => $step->columns || [],
                    data => $data,

                    # Step-specific info
                    step => $step,
                    verb => lc( $step->verb ),
                    text => $text,
            }
            );

        my $result =
            $self->find_and_dispatch( $context,
                                      $outline_state->{'short_circuit'}, 0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            $outline_state->{'short_circuit'}++;
        }

    }

    return;
}


sub _execute_hook_steps {
    my ( $self, $phase, $context_defaults, $outline_state ) = @_;
    my $want_short = ($phase eq 'before');

    for my $step ( @{ $self->{'steps'}->{$phase} || [] } ) {

        my $context = Test::BDD::Cucumber::StepContext->new(
            { %$context_defaults, verb => $phase, } );

        my $result =
            $self->dispatch(
                $context, $step,
                ($want_short ? $outline_state->{'short_circuit'} : 0),
                0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            if ($want_short) {
                $outline_state->{'short_circuit'} = 1;
            }
        }
    }

    return;
}


sub execute_scenario {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background_obj,
        $scenario_stash, $outline_state, $dataset )
      = @$options{
        qw/ feature feature_stash harness scenario background scenario_stash
          outline_state dataset
          /
      };

    my %context_defaults = (
        executor => $self,    # Held weakly by StepContext

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
    $context_defaults{stash}->{scenario} = $scenario_stash;

    $harness->scenario( $outline, $dataset,
                        $scenario_stash->{'longest_step_line'} );

    $_->pre_scenario( $outline, $feature_stash, $scenario_stash )
        for @{ $self->extensions };

    $self->_execute_hook_steps( 'before', \%context_defaults, $outline_state );

    if ($background_obj) {
        $harness->background( $outline, $dataset,
                              $scenario_stash->{'longest_step_line'} );
        $self->_execute_steps(
            {
                scenario       => $background_obj,
                feature        => $feature,
                feature_stash  => $feature_stash,
                harness        => $harness,
                scenario_stash => $scenario_stash,
                outline_state  => $outline_state,
                context_defaults => \%context_defaults,
            }
            );
        $harness->background_done( $outline, $dataset );
    }

    $self->_execute_steps(
        {
            scenario       => $outline,
            feature        => $feature,
            feature_stash  => $feature_stash,
            harness        => $harness,
            scenario_stash => $scenario_stash,
            outline_state  => $outline_state,
            dataset        => $dataset,
            context_defaults => \%context_defaults,
        });

    $self->_execute_hook_steps( 'after', \%context_defaults, $outline_state );

    $_->post_scenario( $outline, $feature_stash, $scenario_stash,
                       $outline_state->{'short_circuit'} )
        for reverse @{ $self->extensions };

    $harness->scenario_done( $outline, $dataset );

    return;
}

=head2 add_placeholders

Accepts a text string and a hashref, and replaces C< <placeholders> > with the
values in the hashref, returning a string.

=cut

sub add_placeholders {
    my ( $self, $text, $dataset, $line ) = @_;
    my $quoted_text = Test::BDD::Cucumber::Util::bs_quote($text);
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die parse_error_from_line( "No mapping to placeholder $1", $line )
    /eg;
    return Test::BDD::Cucumber::Util::bs_unquote($quoted_text);
}


=head2 add_table_placeholders

Accepts a hash with parsed table data and a hashref, and replaces
C< <placeholders> > with the values in the hashref, returning a copy of the
parsed table hashref.

=cut

sub add_table_placeholders {
    my ($self, $tbl, $dataset, $line) = @_;
    my @rv = map {
        my $row = $_;
        my %inner_rv =
            map { $_ => $self->add_placeholders($row->{$_}, $dataset, $line)
        } keys %$row;
        \%inner_rv;
    } @$tbl;
    return \@rv;
}


=head2 find_and_dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and searches through
the steps that have been added to the executor object, executing against the
first matching one.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped, and a boolean flag to denote if it's a redispatched
step.

=cut

sub find_and_dispatch {
    my ( $self, $context, $short_circuit, $redispatch ) = @_;

    # Short-circuit if we need to
    return $self->skip_step( $context, 'pending',
        "Short-circuited from previous tests", 0 )
      if $short_circuit;

    # Try and find a matching step
    my $step = first { $context->text =~ $_->[0] }
    @{ $self->{'steps'}->{ $context->verb } || [] },
      @{ $self->{'steps'}->{'step'} || [] };

    # Deal with the simple case of no-match first of all
    unless ($step) {
        my $message =
            "No matching step definition for: "
          . $context->verb . ' '
          . $context->text;
        my $result =
          $self->skip_step( $context, 'undefined', $message, $redispatch );
        return $result;
    }

    $_->pre_step( $step, $context ) for @{ $self->extensions };
    my $result = $self->dispatch( $context, $step, 0, $redispatch );
    $_->post_step( $step, $context, ( $result->result ne 'passing' ), $result )
      for reverse @{ $self->extensions };
    return $result;
}

=head2 dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and a L<Test::BDD::Cucumber::Step>
object and executes it.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped.

=cut

sub dispatch {
    my ( $self, $context, $step, $short_circuit, $redispatch ) = @_;

    return $self->skip_step( $context, 'pending',
        "Short-circuited from previous tests", $redispatch )
      if $short_circuit;

    # Execute the step definition
    my ( $regular_expression, $meta, $coderef ) = @$step;

    # Setup what we'll pass to step_done, with out localized Test::Builder
    # stuff
    my $output    = '';
    my $tb_return = {
        output  => \$output,
        builder => Test::Builder->create()
    };

    # Set its outputs to be self-referential
    $tb_return->{'builder'}->output( \$output );
    $tb_return->{'builder'}->failure_output( \$output );
    $tb_return->{'builder'}->todo_output( \$output );

    binmode($tb_return->{'builder'}->output(), ':utf8');
    binmode($tb_return->{'builder'}->failure_output(), ':utf8');
    binmode($tb_return->{'builder'}->todo_output(), ':utf8');

    # Make a minimum pass
    $tb_return->{'builder'}
      ->ok( 1, "Starting to execute step: " . $context->text );

    my $step_name = $redispatch ? 'sub_step' : 'step';
    my $step_done_name = $step_name . '_done';

    # Say we're about to start it up
    $context->harness->$step_name($context);

    # Store the string position of matches for highlighting
    my @match_locations;

    # New scope for the localization
    my $result;
    my $stash_keys = join ';', sort keys %{$context->stash};
    {
        # Localize test builder
        local $Test::Builder::Test->{'_wraps'} = $tb_return->{'builder'};

        no warnings 'redefine';
        local *Test::Builder::BAIL_OUT = sub {
            my ( $tb, $message ) = @_;
            $self->_bail_out(1);
            local @CARP_NOT = qw(Test::More Test::BDD::Cucumber::Executor);
            croak("BAIL_OUT() called: $message");
        };

        # Execute!

        # Set S and C to be step-specific values before executing the step
        local *Test::BDD::Cucumber::StepFile::S = sub {
            return $context->stash->{'scenario'};
        };
        local *Test::BDD::Cucumber::StepFile::C = sub {
            return $context;
        };

        # Take a copy of this. Turns out actually matching against it
        # directly causes all sorts of weird-ass heisenbugs which mst has
        # promised to investigate.
        my $text = $context->text;

        # Save the matches
        $context->matches( [ $text =~ $regular_expression ] );

        # Save the location of matched subgroups for highlighting hijinks
        my @starts = @-;
        my @ends   = @+;
        @match_locations = pairwise { [ $a, $b ] } @starts, @ends;

        # OK, actually execute
        eval { $coderef->($context) };
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
    warn qq|Unsupported: Step modified C->stash instead of C->stash->{scenario} or C->stash->{feature}|
        if $stash_keys ne (join ';', sort keys %{$context->stash});

    my @clean_matches =
      $self->_extract_match_strings( $context->text, \@match_locations );
    @clean_matches = [ 0, $context->text ] unless @clean_matches;

    # Say the step is done, and return the result. Happens outside
    # the above block so that we don't have the localized harness
    # anymore...
    $context->harness->add_result($result) unless $redispatch;
    $context->harness->$step_done_name( $context, $result, \@clean_matches );
    return $result;
}

sub _extract_match_strings {
    my ( $self, $text, $locations ) = @_;

    # Clean up the match locations
    my @match_locations = grep {
        ( $_->[0] != $_->[1] ) &&    # No zero-length matches
                                     # And nothing that matched the full string
          ( !( ( $_->[0] == 0 ) && ( ( $_->[1] == length $text ) ) ) )
      } grep {
        defined $_ && ref $_ && defined $_->[0] && defined $_->[1]
      } @$locations;

    return unless @match_locations;

    # Consolidate overlaps
    my $range = Number::Range->new();

    {
        # Don't want a complain about numbers already in range, as that's
        # expected for nested matches
        no warnings;
        $range->addrange( $_->[0] . '..' . ( $_->[1] - 1 ) )
          for @match_locations;
    }

    # Walk the string, splitting
    my @parts = ( [ 0, '' ] );
    for ( 0 .. ( ( length $text ) - 1 ) ) {
        my $to_highlight = $range->inrange($_);
        my $character = substr( $text, $_, 1 );

        if ( $parts[-1]->[0] != $to_highlight ) {
            push( @parts, [ $to_highlight, '' ] );
        }

        $parts[-1]->[1] .= $character;
    }

    return @parts;
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
    my ( $self, $context, $type, $reason, $redispatch ) = @_;

    my $step_name = $redispatch ? 'sub_step' : 'step';
    my $step_done_name = $step_name . '_done';

    # Pretend to start step execution
    $context->harness->$step_name($context);

    # Create a result object
    my $result = Test::BDD::Cucumber::Model::Result->new(
        {
            result => $type,
            output => '1..0 # SKIP ' . $reason
        }
    );

    # Pretend we executed it
    $context->harness->add_result($result) unless $redispatch;
    $context->harness->$step_done_name( $context, $result );
    return $result;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
