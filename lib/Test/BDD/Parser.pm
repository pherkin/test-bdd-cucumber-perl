package Test::BDD::Parser;

=head1 NAME

Test::BDD::Parser - Parse Gherkin feature files

=head1 DESCRIPTION

Parse Gherking feature files in to a set of data classes

=head1 SYNOPSIS

 # Returns a Test::BDD::Model::Feature object
 my $feature = Test::BDD::Parser->parse_file(
    't/data/features/basic_parse.feature' );

=head1 METHODS

=head2 parse_string

=head2 parse_file

Both methods accept a single string as their argument, and return a
L<Test::BDD::Model::Feature> object on success.

=cut

use strict;
use warnings;
use Ouch;

use File::Slurp;
use Test::BDD::Model::Document;
use Test::BDD::Model::Feature;
use Test::BDD::Model::Scenario;
use Test::BDD::Model::Step;

# https://github.com/cucumber/cucumber/wiki/Multiline-Step-Arguments
# https://github.com/cucumber/cucumber/wiki/Scenario-outlines

sub parse_string {
	my ( $self, $string ) = @_;
	return $self->construct( Test::BDD::Model::Document->new({
		content => $string
	}) );
}

sub parse_file   {
	my ( $self, $string ) = @_;
	return $self->construct( Test::BDD::Model::Document->new({
		content  => scalar read_file $string,
		filename => $string
	}) );
}

sub construct {
	my ( $self, $document ) = @_;

	my $feature = Test::BDD::Model::Feature->new({ document => $document });

	$self->extract_scenarios(
	$self->extract_conditions_of_satisfaction(
	$self->extract_feature_name(
		$feature, @{ $document->lines }
	)));

	return $feature;
}

sub extract_feature_name {
	my ( $self, $feature, @lines ) = @_;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;

		# We shouldn't have any indented lines
		ouch 'parse_error', "Inconsistent indentation (not 0)", $line
			unless $line->indent == 0;

		if ( $line->content =~ m/^Feature: (.+)/ ) {
			$feature->name( $1 );
			$feature->name_line( $line );
			last;
		} else {
			ouch 'parse_error', "Malformed feature line", $line;
		}
	}

	return $feature, @lines;
}

sub extract_conditions_of_satisfaction {
	my ( $self, $feature, @lines ) = @_;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;

		# We shouldn't have any lines that aren't indented 2 spaces
		ouch 'parse_error', "Inconsistent indentation (not 2)", $line
			unless $line->indent == 2;

		if ( $line->content =~ m/^(Background|Scenario):/ ) {
			unshift( @lines, $line );
			last;
		} else {
			push( @{ $feature->satisfaction }, $line );
		}
	}

	return $feature, @lines;
}

sub extract_scenarios {
	my ( $self, $feature, @lines ) = @_;
	my $scenarios = 0;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;

		# We shouldn't have any lines that aren't indented 2 spaces
		ouch 'parse_error', "Inconsistent indentation (not 2)", $line
			unless $line->indent == 2;

		if ( $line->content =~ m/^(Background|Scenario)(?: Outline)?: ?(.+)?/ ) {
			my ( $type, $name ) = ( $1, $2 );

			# Only one background section, and it must be the first
			if ( $scenarios++ && $type eq 'Background' ) {
				ouch 'parse_error', "Background not allowed after scenarios",
					$line;
			}

			# Create the scenario
			my $scenario = Test::BDD::Model::Scenario->new({
				( $name ? ( name => $name ) : () ),
				background => $type eq 'Background' ? 1 : 0,
				line       => $line
			});

			# Attempt to populate it
			@lines = $self->extract_steps( $feature, $scenario, @lines );

			push( @{ $feature->scenarios }, $scenario );
		} else {
			ouch 'parse_error', "Malformed scenario line", $line;
		}
	}

	return $feature, @lines;
}

sub extract_steps {
	my ( $self, $feature, $scenario, @lines ) = @_;

	my $last_verb = 'Given';

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;

		# Step back to parsing scenarios if needed
		return( $line, @lines ) if $line->indent == 2;

		# We shouldn't have any lines that aren't indented 4 spaces
		ouch 'parse_error', "Inconsistent indentation (not 4)", $line
			unless $line->indent == 4;

		# Conventional step?
		if ( $line->content =~ m/^(Given|And|When|Then|But) (.+)/ ) {
			my ( $verb, $text ) = ( $1, $2 );
			my $original_verb = $verb;
			$verb = $last_verb if $verb eq 'and' or $verb eq 'but';

			my $step = Test::BDD::Model::Step->new({
				text => $text,
				verb => $verb,
				line => $line,
				original_verb => $verb,
			});

			@lines = $self->extract_step_data(
				$feature, $scenario, $step, @lines );

			push( @{ $scenario->steps }, $step );

		# Outline data block...
		} elsif ( $line->content =~ m/^Examples:$/ ) {
			my ( $self, $indent, $target, @lines ) = @_;
			return $self->extract_table( 6, $scenario, @lines );
		} else {
			ouch 'parse_error', "Malformed step line", $line;
		}
	}

	return @lines;
}

sub extract_step_data {
	my ( $self, $feature, $scenario, $step, @lines ) = @_;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		return @lines if $line->is_blank;

		# Step back as required
		return ($line, @lines) if $line->indent == 4 or $line->indent == 2;

		# We shouldn't have any lines that aren't indented 6 spaces
		ouch 'parse_error', "Inconsistent indentation (not 6)", $line
			unless $line->indent == 6;

		if ( $line->content eq '"""' ) {
			return $self->extract_multiline_string(
				$feature, $scenario, $step, @lines );
		} elsif ( $line->content =~ m/^\|/ ) {
			return $self->extract_table(
				6, $feature, $step, @lines );
		} else {
			ouch 'parse_error', "Malformed step argument", $line;
		}
	}

	return;
}

sub extract_multiline_string {
	my ( $self, $feature, $scenario, $step, @lines ) = @_;

	my $data = '';

	# Check we still have the minimum indentation
	while ( my $line = shift( @lines ) ) {
		ouch 'parse_error', "Unterminated multi-line string", $line
			unless $line->indent >= 6 or $line->is_blank or $line->is_comment;

		if ( $line->content eq '"""' ) {
			ouch 'parse_error', "Inconsistent indentation (not 6)", $line
				unless $line->indent == 6;
			$step->data( $data );
			return @lines;
		}

		my $content = $line->content_remove_indentation( 3 );
		# Unescape it
		$content =~ s/\\(.)/$1/g;
		$content .= "\n";
		$data .= $content;
	}

	return;
}

sub extract_table {
	my ( $self, $indent, $target, @lines ) = @_;

	my @columns;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;
		return @lines if $line->is_blank;

		# Anything smaller than our table, get rid of
		return( $line, @lines ) if $line->indent < $indent;

		# Anything bigger than our table, complain about
		ouch 'parse_error', "Inconsistent indentation (not 6)", $line
			unless $line->indent == 6;

		# Not a | starting the line? That's bad...
		ouch 'parse_error', "Malformed table row", $line
			if index( '|', $line->content );

		my @rows = $self->_pipe_array( $line->content );

		if ( @columns ) {
			ouch 'parse_error', "Inconsistent number of rows in table", $line
				unless @rows == @columns;
			my $i = 0;
			my %data_hash = map { $columns[$i++] => $_ } @rows;
			push( @{ $target->data }, \%data_hash );
		} else {
			@columns = @rows;
		}
	}

	return;
}

sub _pipe_array {
	my ( $self, $string ) = @_;
	my @atoms = split(/\|/, $string);
	shift( @atoms );
	return map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } @atoms;
}

1;

=head1 ERROR HANDLING

L<Test::BDD> uses L<Ouch> for exception handling. Error originating in this
class tend to have a code of C<parse_error> and a L<Test::BDD::Model::Line>
object for data.


