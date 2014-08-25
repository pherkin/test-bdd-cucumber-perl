package Test::BDD::Cucumber::StepContext;

use Moose;
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

has 'columns' => ( is => 'ro', isa => 'ArrayRef' );

=head2 _data

Step-specific data. Will either be a text string in the case of a """ string, or
an arrayref of hashrefs if the step had an associated table.

See the C<data> method below.

=cut

has '_data' =>
  ( is => 'ro', isa => 'Str|ArrayRef', init_arg => 'data', default => '' );

=head2 stash

A hash of hashes, containing three keys, C<feature>, C<scenario> and C<step>.
The stash allows you to persist data across features, scenarios, or steps
(although the latter is there for completeness, rather than having any useful
function).

The scenario-level stash is also available to steps by calling C<S()>, making
the following two lines of code equivalent:

 sub { my $context = shift; my $stash = $context->stash; $stash->{'count'} = 1 }
 sub { S->{'count'} = 1 }

=cut

has 'stash' => ( is => 'ro', required => 1, isa => 'HashRef' );

=head2 feature

=head2 scenario

=head2 step

Links to the L<Test::BDD::Cucumber::Model::Feature>,
L<Test::BDD::Cucumber::Model::Scenario>, and L<Test::BDD::Cucumber::Model::Step>
objects respectively.

=cut

has 'feature' =>
  ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Feature' );
has 'scenario' =>
  ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Scenario' );
has 'step' =>
  ( is => 'ro', required => 0, isa => 'Test::BDD::Cucumber::Model::Step' );

=head2 verb

The lower-cased verb a Step Definition was called with.

=cut

has 'verb' => ( is => 'ro', required => 1, isa => 'Str' );

=head2 text

The text of the step, minus the verb. Placeholders will have already been
multiplied out at this point.

=cut

has 'text' => ( is => 'ro', required => 1, isa => 'Str', default => '' );

=head2 harness

The L<Test::BDD::Cucumber::Harness> harness being used by the executor.

=cut

has 'harness' =>
  ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Harness' );

=head2 matches

Any matches caught by the Step Definition's regex. These are also available as
C<$1>, C<$2> etc as appropriate.

=cut

has '_matches' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    init_arg => 'matches',
    default  => sub { [] }
);

has 'transformers' =>
  ( is => 'ro', isa => 'ArrayRef', predicate => 'has_transformers', );

has '_transformed_matches' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_transformed_matches',
    clearer => '_clear_transformed_matches',
);

has '_transformed_data' => (
    is      => 'ro',
    isa     => 'Str|ArrayRef',
    lazy    => 1,
    builder => '_build_transformed_data',
    clearer => '_clear_transformed_data',
);

=head2 is_hook

The harness processing the output can decide whether to shop information for
this step which is actually an internal hook, i.e. a Before or After step

=cut

has 'is_hook' =>
  ( is => 'ro', isa => 'Bool', lazy => 1, builder => '_build_is_hook' );

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
                my $value = $transformer->[1]->( $self );
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
            $transformer->[1]->( $self, $transformed_data );
        }
    }

    return $transformed_data;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
