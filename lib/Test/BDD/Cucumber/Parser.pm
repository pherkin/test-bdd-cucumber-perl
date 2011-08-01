package Test::BDD::Cucumber::Parser;

=head1 NAME

Test::BDD::Cucumber::Parser - Parse Feature files

=head1 DESCRIPTION

Parse Feature files in to a set of data classes

=head1 SYNOPSIS

 # Returns a Test::BDD::Cucumber::Model::Feature object
 my $feature = Test::BDD::Cucumber::Parser->parse_file(
    't/data/features/basic_parse.feature' );

=head1 METHODS

=head2 parse_string

=head2 parse_file

Both methods accept a single string as their argument, and return a
L<Test::BDD::Cucumber::Model::Feature> object on success.

=cut

use strict;
use warnings;
use Ouch;

use File::Slurp;
use Test::BDD::Cucumber::Model::Document;
use Test::BDD::Cucumber::Model::Feature;
use Test::BDD::Cucumber::Model::Scenario;
use Test::BDD::Cucumber::Model::Step;

# https://github.com/cucumber/cucumber/wiki/Multiline-Step-Arguments
# https://github.com/cucumber/cucumber/wiki/Scenario-outlines

sub parse_string {
	my ( $self, $string ) = @_;
	return $self->construct( Test::BDD::Cucumber::Model::Document->new({
		content => $string
	}) );
}

sub parse_file   {
	my ( $self, $string ) = @_;
	return $self->construct( Test::BDD::Cucumber::Model::Document->new({
		content  => scalar( read_file $string ),
		filename => $string
	}) );
}

sub construct {
	my ( $self, $document ) = @_;

	my $feature = Test::BDD::Cucumber::Model::Feature->new({ document => $document });
    my @lines = $self->remove_next_blanks( @{ $document->lines } );

	$self->extract_scenarios(
	$self->extract_conditions_of_satisfaction(
	$self->extract_feature_name(
        $feature, @lines
	)));

	return $feature;
}

sub remove_next_blanks {
    my ( $self, @lines ) = @_;
    while ($lines[0] && $lines[0]->is_blank) {
        shift( @lines );
    }
    return @lines;
}

sub extract_feature_name {
	my ( $self, $feature, @lines ) = @_;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		last if $line->is_blank;

		if ( $line->content =~ m/^Feature: (.+)/ ) {
			$feature->name( $1 );
			$feature->name_line( $line );
			last;
		} else {
			ouch 'parse_error', "Malformed feature line", $line;
		}
	}

	return $feature, $self->remove_next_blanks( @lines );
}

sub extract_conditions_of_satisfaction {
	my ( $self, $feature, @lines ) = @_;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		last if $line->is_blank;

		if ( $line->content =~ m/^(Background|Scenario):/ ) {
			unshift( @lines, $line );
			last;
		} else {
			push( @{ $feature->satisfaction }, $line );
		}
	}

	return $feature, $self->remove_next_blanks( @lines );
}

sub extract_scenarios {
	my ( $self, $feature, @lines ) = @_;
	my $scenarios = 0;

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		last if $line->is_blank;

		if ( $line->content =~ m/^(Background|Scenario)(?: Outline)?: ?(.+)?/ ) {
			my ( $type, $name ) = ( $1, $2 );

			# Only one background section, and it must be the first
			if ( $scenarios++ && $type eq 'Background' ) {
				ouch 'parse_error', "Background not allowed after scenarios",
					$line;
			}

			# Create the scenario
			my $scenario = Test::BDD::Cucumber::Model::Scenario->new({
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

	return $feature, $self->remove_next_blanks( @lines );
}

sub extract_steps {
	my ( $self, $feature, $scenario, @lines ) = @_;

	my $last_verb = 'Given';

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		last if $line->is_blank;

		# Conventional step?
		if ( $line->content =~ m/^(Given|And|When|Then|But) (.+)/ ) {
			my ( $verb, $text ) = ( $1, $2 );
			my $original_verb = $verb;
			$verb = $last_verb if lc($verb) eq 'and' or $verb eq 'but';
            $last_verb = $verb;

			my $step = Test::BDD::Cucumber::Model::Step->new({
				text => $text,
				verb => $verb,
				line => $line,
				verb_original => $original_verb,
			});

			@lines = $self->extract_step_data(
				$feature, $scenario, $step, @lines );

			push( @{ $scenario->steps }, $step );

		# Outline data block...
		} elsif ( $line->content =~ m/^Examples:$/ ) {
			return $self->extract_table( 6, $scenario,
			    $self->remove_next_blanks( @lines ));
		} else {
		    warn $line->content;
			ouch 'parse_error', "Malformed step line", $line;
		}
	}

	return $self->remove_next_blanks( @lines );
}

sub extract_step_data {
	my ( $self, $feature, $scenario, $step, @lines ) = @_;
    return unless @lines;

    if ( $lines[0]->content eq '"""' ) {
		return $self->extract_multiline_string(
		    $feature, $scenario, $step, @lines );
    } elsif ( $lines[0]->content =~ m/^\s*\|/ ) {
        return $self->extract_table( 6, $step, @lines );
    } else {
        return @lines;
    }

}

sub extract_multiline_string {
	my ( $self, $feature, $scenario, $step, @lines ) = @_;

	my $data = '';
    my $start = shift( @lines );
    my $indent = $start->indent;

	# Check we still have the minimum indentation
	while ( my $line = shift( @lines ) ) {

		if ( $line->content eq '"""' ) {
			$step->data( $data );
			return $self->remove_next_blanks( @lines );
		}

		my $content = $line->content_remove_indentation( $indent );
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

    my $data = [];
    $target->data($data);

	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		return $self->remove_next_blanks( @lines ) if $line->is_blank;
		return ($line, @lines) if index( $line->content, '|' );

		my @rows = $self->_pipe_array( $line->content );

		if ( @columns ) {
			ouch 'parse_error', "Inconsistent number of rows in table", $line
				unless @rows == @columns;
			my $i = 0;
			my %data_hash = map { $columns[$i++] => $_ } @rows;
			push( @$data, \%data_hash );
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

L<Test::BDD::Cucumber> uses L<Ouch> for exception handling. Error originating in this
class tend to have a code of C<parse_error> and a L<Test::BDD::Cucumber::Model::Line>
object for data.


