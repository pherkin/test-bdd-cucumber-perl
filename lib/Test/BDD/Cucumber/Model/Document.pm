package Test::BDD::Cucumber::Model::Document;

use Moose;
use Test::BDD::Cucumber::Model::Line;

=head1 NAME

Test::BDD::Cucumber::Model::Document - Model to represent a feature file on disk
or in memory

=head1 DESCRIPTION

Model to represent a feature file on disk or in memory

=head1 ATTRIBUTES

=head2 filename

The filename from which the document was loaded.

=cut

has 'filename' => ( is => 'ro', isa => 'Str' );

=head2 content

The file contents, as a string

=cut

has 'content'  => ( is => 'ro', isa => 'Str' );

=head2 lines

The file contents, as an arrayref of L<Test::BDD::Cucumber::Model::Line>
objects

=cut

has 'lines'    => ( is => 'rw', default => sub {[]},
	isa => 'ArrayRef[Test::BDD::Cucumber::Model::Line]' );

# Create lines
sub BUILD {
	my $self = shift;

	# Reset any content that was in lines
	my $counter = 0;

	for my $line ( split(/\n/, $self->content ) ) {
		my $obj = Test::BDD::Cucumber::Model::Line->new({
			number      => ++$counter,
			document    => $self,
			raw_content => $line
		});
		push( @{ $self->lines }, $obj );
	}
};

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;