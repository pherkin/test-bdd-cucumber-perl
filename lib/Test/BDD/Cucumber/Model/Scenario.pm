package Test::BDD::Cucumber::Model::Scenario;

use Moose;

=head1 NAME

Test::BDD::Cucumber::Model::Scenario - Model to represent a scenario

=head1 DESCRIPTION

Model to represent a scenario

=head1 ATTRIBUTES

=head2 name

The text after the C<Scenario:> keyword

=cut

has 'name'       => ( is => 'rw', isa => 'Str' );

=head2 steps

The associated L<Test:BDD::Cucumber::Model::Step> objects

=cut

has 'steps'      => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Cucumber::Model::Step]', default => sub {[]} );

=head2 data

Scenario-related data table, as an arrayref of hashrefs

=cut

has 'data'       => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub {[]} );

=head2 background

Boolean flag to mark whether this was the background section

=cut

has 'background' => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 line

A L<Test::BDD::Cucumber::Model::Line> object corresponding to the line where
the C<Scenario> keyword is.

=cut

has 'line'       => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Line' );

=head2 tags

Tags that the scenario has been tagged with, and has inherited from its
feature.

=cut

has 'tags' => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]} );

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
