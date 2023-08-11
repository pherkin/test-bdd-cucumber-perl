use v5.14;
use warnings;

package Test::BDD::Cucumber::StepContext;

use Moo;
use Types::Standard qw( Bool Str HashRef ArrayRef InstanceOf );
use List::Util qw( first );

=head1 NAME

Test::BDD::Cucumber::StepContext - Data made available to step definitions

=head1 DESCRIPTION

The coderefs in Step Definitions have a single argument passed to them, a
C<Test::BDD::Cucumber::StepContext> object. This is an attribute-only class,
populated by L<Test::BDD::Cucumber::Executor>.

When steps are run normally, C<C()> is set directly before execution to return
the context; this allows you to do:

  sub { return C->columns }

instead of:

  sub { my $c = shift; return $c->columns; }

=head1 ATTRIBUTES

=head2 columns

If the step-specific data supplied is a table, the this attribute will contain
the column names in the order they appeared.

=cut

has 'columns' => ( is => 'ro', isa => ArrayRef );

=head2 _data

Step-specific data. Will either be a text string in the case of a """ string, or
an arrayref of hashrefs if the step had an associated table.

See the C<data> method below.

=cut

has '_data' =>
  ( is => 'ro', isa => Str|ArrayRef, init_arg => 'data', default => '' );

=head2 stash

A hash of hashes, containing two keys, C<feature>, C<scenario>.
The stash allows you to persist data across features or scenarios.

The scenario-level stash is also available to steps by calling C<S()>, making
the following two lines of code equivalent:

 sub { my $context = shift; my $stash = $context->stash->{'scenario'}; $stash->{'count'} = 1 }
 sub { S->{'count'} = 1 }

=cut

has 'stash' => ( is => 'ro', required => 1, isa => HashRef );

=head2 feature

=head2 scenario

=head2 step

Links to the L<Test::BDD::Cucumber::Model::Feature>,
L<Test::BDD::Cucumber::Model::Scenario>, and L<Test::BDD::Cucumber::Model::Step>
objects respectively.

=cut

has 'feature' => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf['Test::BDD::Cucumber::Model::Feature']
);
has 'scenario' => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf['Test::BDD::Cucumber::Model::Scenario']
);
has 'step' =>
  ( is => 'ro', required => 0, isa => InstanceOf['Test::BDD::Cucumber::Model::Step'] );

=head2 verb

The lower-cased verb a Step Definition was called with.

=cut

has 'verb' => ( is => 'ro', required => 1, isa => Str );

=head2 text

The text of the step, minus the verb. Placeholders will have already been
multiplied out at this point.

=cut

has 'text' => ( is => 'ro', required => 1, isa => Str, default => '' );

=head2 harness

The L<Test::BDD::Cucumber::Harness> harness being used by the executor.

=cut

has 'harness' =>
  ( is => 'ro', required => 1, isa => InstanceOf['Test::BDD::Cucumber::Harness'] );

=head2 executor

Weak reference to the L<Test::BDD::Cucumber::Executor> being used - this allows
for step redispatch.

=cut

has 'executor' => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf['Test::BDD::Cucumber::Executor'],
    weak_ref => 1
);

=head2 matches

Any matches caught by the Step Definition's regex. These are also available as
C<$1>, C<$2> etc as appropriate.

=cut

has '_matches' => (
    is       => 'rw',
    isa      => ArrayRef,
    init_arg => 'matches',
    default  => sub { [] }
);

has 'transformers' =>
  ( is => 'ro', isa => ArrayRef, predicate => 'has_transformers', );

has '_transformed_matches' => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_transformed_matches',
    clearer => '_clear_transformed_matches',
);

has '_transformed_data' => (
    is      => 'ro',
    isa     => Str|ArrayRef,
    lazy    => 1,
    builder => '_build_transformed_data',
    clearer => '_clear_transformed_data',
);

=head2 is_hook

The harness processing the output can decide whether to shop information for
this step which is actually an internal hook, i.e. a Before or After step

=cut

has 'is_hook' =>
  ( is => 'ro', isa => Bool, lazy => 1, builder => '_build_is_hook' );

=head2 parent

If a step redispatches to another step, the child step will have a link back to
its parent step here; otherwise undef. See L</Redispatching>.

=cut

has 'parent' => ( is => 'ro', isa => InstanceOf['Test::BDD::Cucumber::StepContext'] );

=head1 METHODS

=head2 background

Boolean for "is this step being run as part of the background section?".
Currently implemented by asking the linked Scenario object...

=cut

sub background { my $self = shift; return $self->scenario->background }

=head2 data

See the C<_data> attribute above.

Calling this method will return either the """ string, or a possibly Transform-ed
set of table data.

=cut

sub data {
    my $self = shift;

    if (@_) {
        $self->_data(@_);
        $self->_clear_transformed_data;
        return;
    }

    return $self->_transformed_data;
}

=head2 matches

See the C<_matches> attribute above.

Call this method will return the possibly Transform-ed matches .

=cut

sub matches {
    my $self = shift;

    if (@_) {
        $self->_matches(@_);
        $self->_clear_transformed_matches;
        return;
    }

    return $self->_transformed_matches;
}

=head2 transform

Used internally to transform data and placeholders, but it can also be called
from within your Given/When/Then code.

=cut

sub transform {
    my $self  = shift;
    my $value = shift;

    defined $value or return $value;

  TRANSFORM:
    for my $transformer ( @{ $self->transformers } ) {

        # turn off this warning so undef can be set in the following regex
        no warnings 'uninitialized';

        # uses the same magic as other steps
        # and puts any matches into $1, $2, etc.
        # and calls the Transform step

        # also, if the transformer code ref returns undef, this will be coerced
        # into an empty string, so need to mark it as something else
        # and then turn it into proper undef

        if (
            $value =~ s/$transformer->[0]/
                my $value = $transformer->[2]->( $self );
                defined $value ? $value : '__UNDEF__'
            /e
          )
        {
            # if we matched then stop processing this match
            return $value eq '__UNDEF__' ? undef : $value;
        }
    }

    # if we're here, the value will be returned unchanged
    return $value;
}

=head1 Redispatching

Sometimes you want to call one step from another step. You can do this via the
I<StepContext>, using the C<dispatch()> method. For example:

  Given qr/I have entered (\d+)/, sub {
        C->dispatch( 'Given', "I have pressed $1");
        C_>dispatch( 'Given', "I have passed-in data", C->data );
        C->dispatch( 'Given', "I have pressed enter", { some => 'data' } );
  };

You redispatch step will have its own, new step context with almost everything
copied from the parent step context. However, specifically not copied are:
C<columns>, C<data>, the C<step> object, and of course the C<verb> and the
C<text>.

If you want to pass data to your child step, you should IDEALLY do it via the
text of the step itself, or failing that, through the scenario-level stash.
Otherwise it'd make more sense just to be calling some subroutine... But you
B<can> pass in a third argument - a hashref which will be used as C<data>. The
data in that third argument can be one of:

=over

=item * a string

This scenario corresponds with having a C<""" ... """> string argument
to the step. It's passed to the child step verbatim.

=item * a hash reference (deprecated)

This scenario corresponds with the third example above and has been
supported historically. There is no good reason to use this type of
argument passing, because there is no way for a feature to pass data
to the step. When you need to use this scenario, please consider
implementing a separate subroutine instead.

=item * a reference to an array of hashes

This scenario corresponsds with a data table argument to the step. The
names of the columns are taken from the first hash in the array (the
first row in the data table).

No transformations are applied to the table passed in to prevent
duplicate transformations being applied.

=back

The value of the third argument will be used as the C<< C->data >> value
for the C<StepContext> of the child step. All values passed in, will be
passed to the child without applying C<Transform> declarations. That way,
double transformation is prevented.

If the step you dispatch to doesn't pass for any reason (can't be found, dies,
fails, whatever), it'll throw an exception. This will get caught by the parent
step, which will then fail, and show debugging output.

B<You must use the English names for the step verb, because we have no access to
the parser. Also, remember to quote them as if you're in a step file, there may
be a subroutine defined with the same name.>

=head2 dispatch

    C->dispatch( 'Then', "the page has loaded successfully");

See the paragraphs immediately above this

=cut

sub dispatch {
    my ( $self, $verb, $text, $data ) = @_;

    my $step = Test::BDD::Cucumber::Model::Step->new(
        {
            text => $text,
            verb => $verb,
            line => Test::BDD::Cucumber::Model::Line->new(
                {
                    number      => $self->step->line->number,
                    raw_content => "[Redispatched step: $verb $text]",
                    document    => $self->step->line->document,
                }
            ),
        }
    );

    my $columns;
    if ($data) {
        if ( ref $data eq 'HASH' ) {
            $columns = [ sort keys %$data ];
        }
        elsif ( ref $data eq 'ARRAY'
                and (scalar @{ $data } > 0)
                and ref $data->[0] eq 'HASH' ) {
            $columns = [ sort keys %{ $data->[0] } ];
        }
    }

    my $new_context = $self->new(
        {
            executor => $self->executor,
            ( $data    ? ( data              => $data )    : () ),
            ( $data    ? ( _transformed_data => $data )    : () ),
            ( $columns ? ( columns           => $columns ) : () ),
            stash => {
                feature  => $self->stash->{'feature'},
                scenario => $self->stash->{'scenario'},
                step     => {},
            },
            feature      => $self->feature,
            scenario     => $self->scenario,
            harness      => $self->harness,
            transformers => $self->transformers,

            step => $step,
            verb => lc($verb),
            text => $text,
        }
    );

    my $result = $self->executor->find_and_dispatch( $new_context, 0, 1 );

    # If it didn't pass, short-circuit the rest
    unless ( $result->result eq 'passing' ) {
        my $error = "Redispatched step didn't pass:\n";
        $error .= "\tStatus: " . $result->result . "\n";
        $error .= "\tOutput: " . $result->output . "\n";
        $error .= "Failure to redispatch a step causes the parent to fail\n";
        die $error;
    }

    return $result;
}

# the builder for the is_hook attribute
sub _build_is_hook {
    my $self = shift;

    return ( $self->verb eq 'before' or $self->verb eq 'after' ) ? 1 : 0;
}

# the builder for the _transformed_matches attribute
sub _build_transformed_matches {
    my $self = shift;

    my @transformed_matches = @{ $self->_matches };

    # this stops it recursing forever...
    # and only Transform if there are any to process
    if (    $self->verb ne 'transform'
        and $self->has_transformers )
    {
        @transformed_matches = map {
            my $match = $_;
            $match = $self->transform($match);
        } @transformed_matches;
    }

    return \@transformed_matches;
}

# the builder for the _transformed_data attribute
sub _build_transformed_data {
    my $self = shift;

    my $transformed_data = $self->_data;

    # again stop recursing
    # only transform table data
    # and only Transform if there are any to process
    if (    $self->verb ne 'transform'
        and ref $transformed_data
        and $self->has_transformers )
    {
        # build the string that a Transform is looking for
        # table:column1,column2,column3
        my $table_text = 'table:' . join( ',', @{ $self->columns } );

        if ( my $transformer =
            first { $table_text =~ $_->[0] } @{ $self->transformers } )
        {
            # call the Transform step
            $transformer->[2]->( $self, $transformed_data );
        }
    }

    return $transformed_data;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
