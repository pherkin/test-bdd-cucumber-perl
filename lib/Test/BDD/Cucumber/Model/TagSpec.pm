package Test::BDD::Cucumber::Model::TagSpec;

=head1 NAME

Test::BDD::Cucumber::Model::TagSpec - Encapsulates tag selectors

=head1 DESCRIPTION

Try and deal with the crazy-sauce tagging mechanism in a sane
way.

=cut

use strict;
use warnings;
use Moose;
use Clone qw/clone/;

=head1 OVERVIEW

Cucumber tags are all sortsa crazy. This appears to be a direct result of trying
to shoe-horn the syntax in to something you can use on the command line. Because
'Cucumber' is the name of a gem, application, language, methodology etc etc etc
look of disapproval.

Here is some further reading on how it's meant to work:
L<https://github.com/cucumber/cucumber/wiki/Tags>. This is obviously a little
insane.

Here's how they work here, on a code level: You pass in a list of lists that
look like Lisp expressions, with a function: C<and>, C<or>, or C<not>. You can
nest these to infinite complexity, but the parser is pretty inefficient, so
don't do that. The C<not> function accepts only one argument.

I<eg>:

@important AND @billing: C<<[and => 'important', 'billing']>>

(@billing OR @WIP) AND @important: C<<[ and => [ or => 'billing', 'wip' ], 'important' ]>>

Skipping both @todo and @wip tags: C<<[ and => [ not => 'todo' ], [ not => 'wip' ] ]>>

=head1 ATTRIBUTES

=head2 tags

An arrayref representing a structure like the above.

 TagSet->new({
        tags => [ and => 'green', 'blue', [ or => 'red', 'yellow' ], [ not => 'white' ] ]
 })

=cut

has 'tags' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

=head1 METHODS

=head2 filter

Filter a list of Scenarios by the value of C<tags>

 my @matched = $tagset->filter( @scenarios );

If C<tags> is empty, no filtering is done.

=cut

sub filter {
    my ( $self, @scenarios ) = @_;
    my @tagset = @{ $self->tags };
    return @scenarios unless @tagset;

    my $mode = shift @tagset;

    return grep {
        my @tags = @{ $_->tags };
        my $scenario = { map { $_ => 1 } @tags };

        _matches( $mode, $scenario, \@tagset );
    } @scenarios;
}

# SCHEME ON THE BRAINZ
sub _matches {
    my ( $mode, $scenario, $tags ) = @_;
    $tags = clone $tags;

    # If $tags is null, we have to do something...
    if ( @$tags == 0 ) {

        # True is the unit of conjunction
        ( $mode eq 'and' ) and return 1;

        # False is the unit of disjunction
        ( $mode eq 'or' ) and return 0;

        # We should never get here for anything else
        ( $mode eq 'not' )
          and die "Doesn't make sense to ask for 'not' of empty list";
        die "Don't recognize mode '$mode'";
    }

    # Get the head and tail of $tags. We'll split off the head, and leave the
    # tail in $tags.
    my $head = shift @$tags;

    # Get a result from the next tag. Recurse if it's complex
    my $result =
      ref($head)
      ? _matches( shift(@$head), $scenario, $head )
      : $scenario->{$head};

    if ( $mode eq 'and' ) {
        $result ? return _matches( 'and', $scenario, $tags ) : return 0;
    } elsif ( $mode eq 'or' ) {
        $result ? return 1 : return _matches( 'or', $scenario, $tags );
    } elsif ( $mode eq 'not' ) {
        return !$result;
    } else {
        die "Don't recognize mode '$mode'";
    }
}

1;
