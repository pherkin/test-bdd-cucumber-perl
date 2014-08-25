package Test::BDD::Cucumber::Util;

use strict;
use warnings;

=head1 NAME

Test::BDD::Cucumber::Util - Some functions used throughout the code

=head1 DESCRIPTION

Some functions used throughout the code

=head1 FUNCTIONS

=head2 bs_quote

=head2 bs_unquote

C<bs_quote()> "makes safe" strings with backslashed characters in it, so other
operations can be done on them. C<bs_unquote> goes the other way.

 $string = "foo \<bar\> <baz>";
 $string = bs_quote( $string );
 $string =~ s/<([^>]+)>/"$1"/g;
 $string = bs_unquote( $string );
 $string eq 'foo <bar> "baz"';

=cut

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

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
