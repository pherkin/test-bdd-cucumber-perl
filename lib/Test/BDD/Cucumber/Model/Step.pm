package Test::BDD::Cucumber::Model::Step;

use Moose;

=head1 NAME

Test::BDD::Cucumber::Model::Step - Model to represent a step in a scenario

=head1 DESCRIPTION

Model to represent a step in a scenario

=head1 ATTRIBUTES

=head2 text

The text of the step, once Scenario Outlines have been applied

=cut

has 'text' => ( is => 'rw', isa => 'Str' );

=head2 verb

=head2 verb_original

The verb used for the step ('Given'/'When'/etc). C<verb_original> is the one
that appeared in the physical file - this will sometimes be C<and>.

=cut

has 'verb'          => ( is => 'rw', isa => 'Str' );
has 'verb_original' => ( is => 'rw', isa => 'Str' );

=head2 line

The corresponding L<Test:BDD::Cucumber::Model::Line>

=cut

has 'line' => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Line' );

=head2 data

Step-related data. Either a string in the case of C<"""> or an arrayref of
hashrefs for a data table.

=cut

has 'data' => ( is => 'rw' );

=head2 data_as_strings

An arrayref of strings containing the original step's data, for printing out
by harnesses

=cut

has 'data_as_strings' => (
    is      => 'rw',
    default => sub { [] },
    isa     => 'ArrayRef[Str]'
);

=head2 columns

If data was in a table format, then the column names will be here in the order
they appeared.

=cut

has 'columns' => ( is => 'rw', isa => 'ArrayRef[Str]' );

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
