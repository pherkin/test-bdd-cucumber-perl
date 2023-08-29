use v5.14;
use warnings;

package Test::BDD::Cucumber::Model::TagSpec;

=head1 NAME

Test::BDD::Cucumber::Model::TagSpec - Encapsulates tag selectors

=head1 STATUS

DEPRECATED - This module's functionality has been superseded by
L<Cucumber::TagExpressions>. A module published by the Cucumber
project, with cross-implementation tests to achieve overall consistency.

=head1 DESCRIPTION

Try and deal with the crazy-sauce tagging mechanism in a sane
way.

=cut

use Moo;
use List::Util qw( all any );
use Types::Standard qw( ArrayRef );

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

has 'tags' => ( is => 'rw', isa => ArrayRef, default => sub { [] } );

=head1 METHODS

=head2 filter

Filter a list of Scenarios by the value of C<tags>

 my @matched = $tagset->filter( @scenarios );

If C<tags> is empty, no filtering is done.

=cut

sub filter {
    my ( $self, @scenarios ) = @_;
    return @scenarios unless @{ $self->tags };

    return grep {
        my @tags = @{ $_->tags };
        my $scenario = { map { $_ => 1 } @tags };

        _matches( $scenario, $self->tags );
    } @scenarios;
}

sub _matches {
    my ( $scenario, $tagspec ) = @_;
    my ( $mode, @tags ) = @$tagspec;

    if ( $mode eq 'and' ) {
        return all {
            ref $_ ? _matches( $scenario, $_ ) : $scenario->{$_}
        } @tags;
    }
    elsif ( $mode eq 'or' ) {
        return any {
            ref $_ ? _matches( $scenario, $_ ) : $scenario->{$_}
        } @tags;
    }
    elsif ( $mode eq 'not' ) {
        die "'not' expects exactly one tag argument; found @tags"
            unless @tags == 1;

        return
            not (ref $tags[0]
                 ? _matches( $scenario, $tags[0] )
                 : $scenario->{$tags[0]}
            );
    }
    else {
        die "Unexpected tagspec operator '$mode'";
    }
}

1;
