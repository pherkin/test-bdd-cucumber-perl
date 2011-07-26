package Test::BDD::Parser;

use strict;
use warnings;

sub parse {
	my ( $self, @lines ) = @_;

	my $data = {};

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
}

sub _create_scenario {
	return { lines => [], examples => [] };
}

sub _pipe_array {
	my ( $self, $string ) = @_;
	my @atoms = split(/\|/, $string);
	shift( @atoms );
	return map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } @atoms;
}

1;
