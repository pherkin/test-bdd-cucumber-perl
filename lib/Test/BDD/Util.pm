package Test::BDD::Util;

use strict;
use warnings;

my $marker_start = ';;;TEST_BDD_TEMP_MARKER_OPEN;;;';
my $marker_end   = ';;;TEST_BDD_TEMP_MARKER_END;;;';

sub bs_quote {
	my $string = shift;
	$string =~ s/\\(.)/${marker_start} . ord($1) . ${marker_end}/ge;
	return $string;
}

sub bs_unquote {
	my $string = shift;
	$string =~ s/$marker_start(\d+)$marker_end/chr($1)/ge;
	return $string;
}

1;