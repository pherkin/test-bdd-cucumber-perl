package Test::BDD::Cucumber::Errors;

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_error_from_line);

=head1 NAME

Test::BDD::Cucumber::Errors - Consistently formatted errors

=head1 DESCRIPTION

Consistently formatted errors

=head1 NOTE

This module is not intended to help throw error classes, simply to provide
helpers for consistently formatting certain errors. Most of the errors thrown in
practice are errors with the input test scenarios, and it's helpful to have the
location of the error and context when debugging those. Perhaps in the future
these can return error objects.

All current uses (2016-02-09) just pass the results straight to die, so I
have decided to UTF8 encode the error message on the basis that this probably
constitutes an application boundary.

=head1 SYNOPSIS

  use Test::BDD::Cucumber::Errors qw/parse_error_from_line/;

  parse_error_from_line(
    "Your input was bad",
    $line
  );

=head1 PARSER ERRORS

=head2 parse_error_from_line

Generates a parser error from a L<Test::BDD::Cucumber::Model::Line> object, and
error reason:

  parse_error_from_line(
    "Your input was bad",
    $line
  );

=cut

sub parse_error_from_line {
    my ( $message, $line ) = @_;

    my $error = "-- Parse Error --\n\n $message\n";
    $error .= "  at [%s] line %d\n";
    $error .= "  thrown by: [%s] line %d\n\n";
    $error .= "-- [%s] --\n\n";
    $error .= "%s";
    $error .= "\n%s\n";

    # Get the caller data
    my ( $caller_filename, $caller_line ) = ( caller() )[ 1, 2 ];

    # Get the simplistic filename and line number it occurred on
    my $feature_filename = $line->document->filename || "(no filename)";
    my $feature_line = $line->number;

    # Get the context lines
    my ( $start_line, @lines ) =
      _get_context_range( $line->document, $feature_line );

    my $formatted_lines;
    for ( 0 .. $#lines ) {
        my $actual_line = $start_line + $_;
        my $mark = ( $feature_line == $actual_line ) ? '*' : '|';
        $formatted_lines .=
          sprintf( "% 3d%s    %s\n", $actual_line, $mark, $lines[$_] );
    }

    my $to_return = sprintf( $error,
        $feature_filename, $feature_line,
        $caller_filename,  $caller_line,
        $feature_filename, $formatted_lines,
        ( '-' x ( ( length $feature_filename ) + 8 ) ) );

    utf8::encode($to_return);
    return $to_return;
}

sub _get_context_range {
    my ( $document, $number ) = @_;

    # Context range
    my $min_range = 1;
    my $max_range = ( scalar @{ $document->lines } );

    my @range = ( $number - 2, $number - 1, $number, $number + 1, $number + 2 );

    # Push the range higher if needed
    while ( $range[0] < $min_range ) {
        @range = map { $_ + 1 } @range;
    }

    # Push the range lower if needed
    while ( $range[4] > $max_range ) {
        @range = map { $_ - 1 } @range;
    }

    # Then cut it off
    @range = grep { $_ >= $min_range } @range;
    @range = grep { $_ <= $max_range } @range;

    return ( $range[0],
        map { $document->lines->[ $_ - 1 ]->raw_content } @range );
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
