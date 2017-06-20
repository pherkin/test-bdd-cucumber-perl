package Test::BDD::Cucumber::Model::Line;

use Moo;
use Types::Standard qw( Int InstanceOf Str );

=head1 NAME

Test::BDD::Cucumber::Model::Line - Model to represent a line in a feature file

=head1 DESCRIPTION

Model to represent a line in a feature file

=head1 ATTRIBUTES

=head2 number

The line number this line represents

=cut

has 'number' => ( is => 'rw', isa => Int );

=head2 document

The L<Test::BDD::Cucumber::Model::Document> object this line belongs to.

=cut

has 'document' => ( is => 'rw', isa => InstanceOf['Test::BDD::Cucumber::Model::Document'] );

=head2 raw_content

The content of the line, unmodified

=cut

has 'raw_content' => ( is => 'rw', isa => Str );

=head1 METHODS

=head2 indent

Returns the number of preceding spaces before content on a line

=cut

sub indent {
    my $self = shift;
    my ($indent) = $self->raw_content =~ m/^( +)/g;
    return length( $indent || '' );
}

=head2 content

Returns the line's content, with the indentation stripped

=cut

sub content { return _strip( $_[0]->raw_content ) }

=head2 content_remove_indentation

Accepts an int of number of spaces, and returns the content with exactly that
many preceding spaces removed.

=cut

sub content_remove_indentation {
    my ( $self, $indent ) = @_;
    $indent = ' ' x $indent;
    my $content = $self->raw_content;
    $content =~ s/^$indent//;
    return $content;
}

=head2 debug_summary

Returns a string with the filename and line number

=cut

sub debug_summary {
    my $self     = shift;
    my $filename = $self->filename;
    return
        "Input: $filename line "
      . $self->number . ": ["
      . $self->raw_content . "]";
}

=head2 filename

Returns either the filename, or the string C<[String]> if the document was
loaded from a string

=cut

sub filename {
    my $self = shift;
    $self->document->filename || '[String]';
}

=head2 is_blank

=head2 is_comment

Return true if the line is either blank, or is a comment.

=cut

sub is_blank   { return !( $_[0]->content =~ m/\S/ ) }
sub is_comment { return scalar $_[0]->content =~ m/^\s*#/ }

sub _strip {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
