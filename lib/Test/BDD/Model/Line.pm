package Test::BDD::Model::Line;

use Moose;

has 'number'      => ( is => 'rw', isa => 'Int' );
has 'document'    => ( is => 'rw', isa => 'Test::BDD::Model::Document' );
has 'raw_content' => ( is => 'rw', isa => 'Str' );
has 'related'     => ( is => 'rw', weak_ref => 1, isa => 'HashRef' );

sub indent {
	my $self = shift;
	my ($indent) = $self->raw_content =~ m/^( +)/g;
	return length( $indent || '' );
}

sub content { return _strip( $_[0]->raw_content ) }

sub content_remove_indentation {
	my ( $self, $indent ) = @_;
	$indent = ' ' x ( 2 * $indent );
	my $content = $self->raw_content;
	$content =~ s/^$indent//;
	return $content;
}

sub debug_summary {
	my $self = shift;
	my $filename = $self->document->filename || '[String]';
	return "Input: $filename line " . $self->number . ": [" . $self->raw_content . "]";
}

sub is_blank   { return ! ( $_[0]->content =~ m/\S/ ) }
sub is_comment { return scalar $_[0]->content =~ m/^#/ }

sub _strip {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

1;