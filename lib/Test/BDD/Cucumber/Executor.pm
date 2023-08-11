
use v5.14;
use warnings;

package Test::BDD::Cucumber::Executor;

=head1 NAME

Test::BDD::Cucumber::Executor - Run through Feature and Harness objects

=head1 DESCRIPTION

The Executor runs through Features, matching up the Step Lines with Step
Definitions, and reporting on progress through the passed-in harness.

=cut

use Moo;
use MooX::HandlesVia;
use Types::Standard qw( Bool Str ArrayRef HashRef );
use List::Util qw/first any/;
use Module::Runtime qw/use_module/;
use utf8;
use Carp qw(carp croak);
use Encode ();

use Test2::API qw/intercept/;

# Use-ing the formatter results in a
# 'loaded too late to be used globally' warning
# But we only need it locally anyway.
require Test2::Formatter::TAP;

use Test2::Tools::Basic qw/ pass fail done_testing /;
# Needed for subtest() -- we don't want to import all its functions though
require Test::More;

use Test::BDD::Cucumber::StepFile ();
use Test::BDD::Cucumber::StepContext;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Model::Result;
use Test::BDD::Cucumber::Errors qw/parse_error_from_line/;

=head1 ATTRIBUTES

=head2 matching

The value of this attribute should be one of C<first> (default), C<relaxed> and C<strict>.

By default (C<first>), the first matching step is executed immediately,
terminating the search for (further) matching steps. When C<matching> is set
to anything other than C<first>, all steps are checked for matches. When set
to C<relaxed>, a warning will be generated on multiple matches. When set to
C<strict>, an exception will be thrown.

=cut

has matching => ( is => 'rw', isa => Str, default => 'first');

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
L<Cucumber::TagExpressions::ExpressionNode> object and for each scenario in the
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

    $_->pre_feature( $feature, $feature_stash ) for @{ $self->extensions };
    for my $outline (@scenarios) {

        # Execute the scenario itself
        $self->execute_outline(
            {
                @background,
                scenario      => $outline,
                feature       => $feature,
                feature_stash => $feature_stash,
                harness       => $harness,
                tagspec       => $tag_spec,
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

sub _match_tags {
    my ($spec, @tagged_components) = @_;
    state $deprecation_warned = 0;

    if ($spec->isa('Cucumber::TagExpressions::ExpressionNode')) {
        return grep {
            $spec->evaluate( @{ $_->tags } )
        } @tagged_components;
    }
    else {
        $deprecation_warned ||=
            carp 'Test::BDD::Cucumber::Model::TagSpec is deprecated; replace with Cucumber::TagExpressions';

        return $spec->filter( @tagged_components );
    }
}

sub execute_outline {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background, $tagspec )
      = @$options{qw/ feature feature_stash harness scenario background tagspec /};

    # Multiply out Scenario Outlines as appropriate
    my @datasets = @{ $outline->datasets };
    if (not @datasets) {
        if (not $tagspec or _match_tags( $tagspec, $outline )) {
            $self->execute_scenario(
                {
                    feature => $feature,
                    feature_stash => $feature_stash,
                    harness => $harness,
                    scenario => $outline,
                    background => $background,
                    scenario_stash => {},
                    dataset => {},
                });
        }

        return;
    }

    if ($tagspec) {
        @datasets = _match_tags( $tagspec, @datasets );
        return unless @datasets;
    }


    foreach my $rows (@datasets) {

        foreach my $row (@{$rows->data}) {

            my $name = $outline->{name} || "";
            $name =~ s/\Q<$_>\E/$row->{$_}/g
                for (keys %$row);
            local $outline->{name} = $name;

            $self->execute_scenario(
                {
                    feature => $feature,
                    feature_stash => $feature_stash,
                    harness => $harness,
                    scenario => $outline,
                    background => $background,
                    scenario_stash => {},
                    dataset => $row,
                });
        }
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
        $scenario_stash, $scenario_state, $dataset, $context_defaults )
      = @$options{
        qw/ feature feature_stash harness scenario scenario_stash
          scenario_state dataset context_defaults
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
                                      $scenario_state->{'short_circuit'}, 0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            $scenario_state->{'short_circuit'}++;
        }

    }

    return;
}


sub _execute_hook_steps {
    my ( $self, $phase, $context_defaults, $scenario_state ) = @_;
    my $want_short = ($phase eq 'before');

    for my $step ( @{ $self->{'steps'}->{$phase} || [] } ) {

        my $context = Test::BDD::Cucumber::StepContext->new(
            { %$context_defaults, verb => $phase, } );

        my $result =
            $self->dispatch(
                $context, $step,
                ($want_short ? $scenario_state->{'short_circuit'} : 0),
                0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            if ($want_short) {
                $scenario_state->{'short_circuit'} = 1;
            }
        }
    }

    return;
}


sub execute_scenario {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background_obj,
        $scenario_stash, $dataset )
      = @$options{
        qw/ feature feature_stash harness scenario background scenario_stash
          dataset
          /
    };
    my $scenario_state = {};

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

    $self->_execute_hook_steps( 'before', \%context_defaults, $scenario_state );

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
                scenario_state  => $scenario_state,
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
            scenario_state  => $scenario_state,
            dataset        => $dataset,
            context_defaults => \%context_defaults,
        });

    $self->_execute_hook_steps( 'after', \%context_defaults, $scenario_state );

    $_->post_scenario( $outline, $feature_stash, $scenario_stash,
                       $scenario_state->{'short_circuit'} )
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
first matching one (unless C<$self->matching> indicates otherwise).

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
    my $stepdef;
    my $text = $context->text;
    if ($self->matching eq 'first') {
        $stepdef = first { $text =~ $_->[0] }
        @{ $self->{'steps'}->{ $context->verb } || [] },
            @{ $self->{'steps'}->{'step'} || [] };
    }
    else {
        my @stepdefs = grep { $text =~ $_->[0] }
        @{ $self->{'steps'}->{ $context->verb } || [] },
            @{ $self->{'steps'}->{'step'} || [] };

        if (@stepdefs > 1) {
            my $filename = $context->step->line->document->filename;
            my $line = $context->step->line->number;
            my $msg =
                join("\n   ",
                     qq(Step "$text" ($filename:$line) matches multiple step functions:),
                     map {
                       qq{matcher $_->[0] defined at } .
                           (($_->[1]->{source} && $_->[1]->{line})
                            ? "$_->[1]->{source}:$_->[1]->{line}"
                            : '<unknown>') } @stepdefs);

            if ($self->matching eq 'relaxed') {
                warn $msg;
            }
            else {
                die $msg;
            }
        }
        $stepdef = shift @stepdefs;
    }

    # Deal with the simple case of no-match first of all
    unless ($stepdef) {
        my $message =
            "No matching step definition for: "
          . $context->verb . ' '
          . $context->text;
        my $result =
          $self->skip_step( $context, 'undefined', $message, $redispatch );
        return $result;
    }

    $_->pre_step( $stepdef, $context ) for @{ $self->extensions };
    my $result = $self->dispatch( $context, $stepdef, 0, $redispatch );
    $_->post_step( $stepdef, $context,
                   ( $result->result ne 'passing' ), $result )
      for reverse @{ $self->extensions };
    return $result;
}

=head2 dispatch($context, $stepdef, $short_circuit, $redispatch)

Accepts a L<Test::BDD::Cucumber::StepContext> object, and a
reference to a step definition triplet (verb, metadata hashref, coderef)
and executes it the coderef.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped.

=cut

sub dispatch {
    my ( $self, $context, $stepdef, $short_circuit, $redispatch ) = @_;

    return $self->skip_step( $context, 'pending',
        "Short-circuited from previous tests", $redispatch )
      if $short_circuit;

    # Execute the step definition
    my ( $regular_expression, $meta, $coderef ) = @$stepdef;

    my $step_name = $redispatch ? 'sub_step' : 'step';
    my $step_done_name = $step_name . '_done';

    # Say we're about to start it up
    $context->harness->$step_name($context);

    my @match_locations;
    my $stash_keys = join ';', sort keys %{$context->stash};
    # Using `intercept()`, run the step function in an isolated
    # environment -- this should not affect the enclosing scope
    # which might be a TAP::Harness scope.
    #
    # Instead, we want the tests inside this scope to map to
    # status values
    my $events = intercept {
        # This is a hack to make Test::More's $TODO variable work
        # inside the intercepted scope.

        ###TODO: Both intercept() and Test::More::subtest() should
        # be replaced by a specific Hub implementation for T::B::C
        Test::More::subtest( 'execute step', sub {

            # Take a copy of this. Turns out actually matching against it
            # directly causes all sorts of weird-ass heisenbugs which mst has
            # promised to investigate.
            my $text = $context->text;

            # Save the matches
            $context->matches( [ $text =~ $regular_expression ] );

            # Save the location of matched subgroups for highlighting hijinks
            my @starts = @-;
            my @ends   = @+;

            # Store the string position of matches for highlighting
            @match_locations = map { [ $_, shift @ends ] } @starts;

            # OK, actually execute
            local $@;
            eval {
                no warnings 'redefine';

                local *Test::BDD::Cucumber::StepFile::_S = sub {
                    return $context->stash->{'scenario'};
                };
                local *Test::BDD::Cucumber::StepFile::_C = sub {
                    return $context;
                };

                $coderef->($context)
            };
            if ($@) {
                fail("Step ran to completion", "Exception: ", $@);
            }
            else {
                pass("Step ran to completion");
            }

            done_testing();
                             });
    };

    my $status = $self->_test_status( $events );

    my $result = Test::BDD::Cucumber::Model::Result->new(
        {
            result => $status,
            # due to the hack above with the subtest inside the
            # interception scope, we need to grovel the subtest
            # from out of the other results first.
            output => $self->_test_output(
                (first { $_->isa('Test2::Event::Subtest') }
                 @$events)->{subevents}),
        });
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

    my %range =
        map { $_ => 1 } map { $_->[0] .. ($_->[1] - 1) } @match_locations;

    # Walk the string, splitting
    my @parts = ( [ 0, '' ] );
    for ( 0 .. ( ( length $text ) - 1 ) ) {
        my $to_highlight = $range{$_} || 0;
        my $character = substr( $text, $_, 1 );

        if ( $parts[-1]->[0] != $to_highlight ) {
            push( @parts, [ $to_highlight, '' ] );
        }

        $parts[-1]->[1] .= $character;
    }

    return @parts;
}

sub _test_output {
    my ($self, $events) = @_;
    my $fmt = Test2::Formatter::TAP->new();
    open my $stdout, '>:encoding(UTF-8)', \my $out_text;
    my $idx = 0;

    $fmt->set_handles([ $stdout, $stdout ]);
    $self->_test_output_from_subevents($events, $fmt, \$idx);
    close $stdout;

    return Encode::decode('utf8', $out_text);
}

sub _test_output_from_subevents {
    my ($self, $events, $fmt, $idx) = @_;

    for my $event (@$events) {
        if ($event->{subevents}) {
            $self->_test_output_from_subevents(
                $event->{subevents}, $fmt, $idx);
        }
        else {
            $fmt->write($event, $$idx++);
        }
    }
}

sub _test_status {
    my $self    = shift;
    my $events  = shift;

    if (any { defined $_->{effective_pass}
              and ! $_->{effective_pass} } @$events) {
        return 'failing';
    }
    else {
        return $self->_test_status_from_subevents($events) ? 'pending' : 'passing';
    }
}

sub _test_status_from_subevents {
    my $self    = shift;
    my $events  = shift;

    for my $e (@$events) {
        if (exists $e->{subevents}) {
            $self->_test_status_from_subevents($e->{subevents})
                and return 1;
        }
        elsif (defined $e->{amnesty}
               and $e->{effective_pass}
               and (not $e->{pass})
               and any { $_->{tag} eq 'TODO' } @{$e->{amnesty}}) {
            return 1;
        }
    }

    return 0;
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

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
