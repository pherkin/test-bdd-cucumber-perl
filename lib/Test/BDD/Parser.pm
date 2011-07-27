package Test::BDD::Parser;

use strict;
use warnings;
use Ouch;

use File::Slurp;
use Test::BDD::Model::Document;
use Test::BDD::Model::Feature;

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

	if ( kiss 'parse_error' ) {
		die $@->scalar;
	}

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

		if ( $line->content =~ m/^(Background|Scenario(?: Outline)): (.+)/ ) {
			my ( $type, $title ) = ( $1, $2 );

			# Only one background section, and it must be the first
			if ( $scenarios++ && $type eq 'Background' ) {
				ouch 'parse_error', "Background not allowed after scenarios",
					$line;
			}

			# Create the scenario
			my $scenario = Test::BDD::Model::Scenario->new({
				title      => $title,
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

	# Extract the feature name
	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment || $line->is_blank;

		# We shouldn't have any lines that aren't indented 4 spaces
		ouch 'parse_error', "Inconsistent indentation (not 4)", $line
			unless $line->indent == 4;

		if ( $line->content =~ m/^(Given|And|When|Then|But) (.+)/ ) {
			my ( $verb, $text ) = ( $1, $2 );
			$verb = $last_verb if $verb eq 'and' or $verb eq 'but';

			my $step = Test::BDD::Model::Step->new({
				text => $text,
				verb => $verb,
				line => $line
			});

			@lines = $self->extract_step_data(
				$feature, $scenario, $step, @lines );

			push( @{ $scenario->steps }, $step );

		} elsif ( $line->content =~ m/^Examples:$/ ) {
			@lines = $self->extract_outline( $feature, $scenario, @lines );

		} else {
			ouch 'parse_error', "Malformed step line", $line;
		}
	}
}

sub extract_step_data {
	my ( $self, $feature, $scenario, $step, @lines ) = @_;

	# Extract the feature name
	while ( my $line = shift( @lines ) ) {
		next if $line->is_comment;
		return if $line->is_blank;

	}
}

1;

__DATA__

	# Extract the feature name
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

	# Extract conditions of satisfaction
	while ( my $line = shift( @lines ) ) {

	my $state_machine = {
		feature_defined  => 0,
		background_seen  => 0,
		scenarios_seen   => 0,
		parsing_scenario => 0,
		current_indent   => 0,
		in_cdata         => 0,
		cdata_text       => ''
	};

	for my $line (@{ $document->lines }) {

		# Keep sucking down a data section if we're in one
		if ( $state_machine->{'in_cdata'} ) {
			# Check we still have the minimum indentation
			die "Unterminated data section" . $line->raw_content
				if !$line->is_blank && $line->indent < 3;

			# Wrap it up if appropriate
			if ( $line->content eq '"""' ) {
				die "Inconsistent indentation: " . $line->raw_content
					unless $line->indent == 3;
				$state_machine->{'in_cdata'} = 0;
				warn "Throwing away cdata state";

			# Content line (potentially)
			} else {
				my $content = $line->content_remove_indentation( 3 );
				# Unescape it
				$content =~ s/\\(.)/$1/g;
				$content .= "\n";
				$state_machine->{'cdata_text'} .= $content;
			}

			next;
		}

		next if $line->is_comment;

		# Still looking for the feature definition?
		if (! $state_machine->{'feature_defined'} ) {
			next if $line->is_blank;
			if ( $line->content =~ m/^Feature: (.+)/ ) {
				$feature->name( $1 );
				$feature->name_line( $line );
				$state_machine->{'feature_defined'} = 1;
			} else {
				die "Malformed feature line: " . $line->content;
			}
			next;
		}

		# What to do if we're in the middle of parsing a scenario
		if ( $state_machine->{'parsing_scenario'} ) {
			next if $line->is_blank;

		}

		next if $line->is_blank;

		die "Inconsistent indentation (" . $line->indent . "): " . $line->raw_content
			unless $line->indent == 1;

		if ( $line->content =~ m/^(Scenario|Background):/ ) {
			 warn "Deal with scenarios here";
			 next;
		}

		if ( $state_machine->{'scenarios_seen'} ) {
			die "Line isn't scenario, background, or cond of sat"
				. $line->content;
		}

		push( @{ $feature->satisfaction }, $line );

	}

	return $feature;

}

sub _pipe_array {
	my ( $self, $string ) = @_;
	my @atoms = split(/\|/, $string);
	shift( @atoms );
	return map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } @atoms;
}

1;

__DATA__


	my $data;
	my @lines;
	# Find the feature
	while ( my $line = shift( @lines ) ) {
		next unless $line =~ m/\w/;
		if ( $line =~ m/^Feature: (.+)/ ) {
			$data->{'title'} = $1;
			last;
		} else {
			die "Malformed feature line: $line";
		}
	}

	$data->{'satisfaction'} = {lines => []};
	$data->{'background'}   = {lines => [], name => 'Background Section'};
	$data->{'scenarios'}    = [];

	my $cursor = $data->{'satisfaction'}->{'lines'};

	for my $line (@lines) {
		if ( $line =~ m/^(?: ){2}Background:/ ) {
			$cursor = $data->{'background'}->{'lines'};
		} elsif ( $line =~ m/^(?: ){2}Scenario Outline: (.+)/ ) {
			my $scenario = $self->_create_scenario();
			$scenario->{'name'} = $1;
			push( @{$data->{'scenarios'}}, $scenario );
			$cursor = $scenario->{'lines'};
		} elsif ( $line =~ m/^(?: ){4}Examples:/ ) {
			$cursor = $data->{'scenarios'}->[-1]->{'examples'};
		} else {
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			next unless $line =~ m/\w/;
			push( @$cursor, $line );
		}
	}

	for my $ref (
		$data->{'background'},
		@{ $data->{'scenarios'} }
	) {
		my $last_verb = '';
		my @actions;

		for my $line ( @{$ref->{'lines'}} ) {
			unless ( $line =~ s/^(given|and|when|then|but)\s+//i ) {
				warn "$line doesn't start with a recognizable action - skipping";
				next;
			}
			my $verb = lc($1);
			$verb = $last_verb if $verb eq 'and' or $verb eq 'but';
			$last_verb = $verb;

			push( @actions, [ $verb, $line ] );
		}

		$ref->{'lines'} = \@actions;
	}

	for my $ref ( @{ $data->{'scenarios'} } ) {
		next unless eval { @{ $ref->{'examples'} } };
		my @lines = @{ $ref->{'examples'} };
		my @keys = $self->_pipe_array( shift( @lines ) );
		my @data_array;
		for my $line ( @lines ) {
			my @values = $self->_pipe_array( $line );
			my $i = 0;
			my %data_hash = map { $keys[$i++] => $_ } @values;
			push( @data_array, \%data_hash );
		}
		$ref->{'examples'} = \@data_array;
	}

	$data;