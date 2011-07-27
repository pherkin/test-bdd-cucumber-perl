package Test::BDD::Model::Document;

use Moose;
use Test::BDD::Model::Line;

has 'filename' => ( is => 'ro', isa => 'Str' );
has 'content'  => ( is => 'ro', isa => 'Str' );
has 'lines'    => ( is => 'rw', default => sub {[]},
	isa => 'ArrayRef[Test::BDD::Model::Line]' );

# Create lines
sub BUILD {
	my $self = shift;

	# Reset any content that was in lines
	my $counter = 0;

	for my $line ( split(/\n/, $self->content ) ) {
		my $obj = Test::BDD::Model::Line->new({
			number      => ++$counter,
			document    => $self,
			raw_content => $line
		});
		push( @{ $self->lines }, $obj );
	}
};

1;