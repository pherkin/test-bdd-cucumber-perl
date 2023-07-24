package Test::BDD::Cucumber::Model::Feature;

use Moo;
use Types::Standard qw( Str ArrayRef InstanceOf );

=head1 NAME

Test::BDD::Cucumber::Model::Feature - Model to represent a feature file, parsed

=head1 DESCRIPTION

Model to represent a feature file, parsed

=head1 ATTRIBUTES

=head2 name

The text after the C<Feature:> keyword

=cut

has 'name' => ( is => 'rw', isa => Str );

=head2 name_line

A L<Test::BDD::Cucumber::Model::Line> object corresponding to the line the
C<Feature> keyword was found on

=cut

has 'name_line' => ( is => 'rw', isa => InstanceOf['Test::BDD::Cucumber::Model::Line'] );

=head2 satisfaction

An arrayref of strings of the Conditions of Satisfaction

=cut

has 'satisfaction' => (
    is      => 'rw',
    isa     => ArrayRef[InstanceOf['Test::BDD::Cucumber::Model::Line']],
    default => sub { [] }
);

=head2 document

The corresponding L<Test::BDD::Cucumber::Model::Document> object

=cut

has 'document' => ( is => 'rw', isa => InstanceOf['Test::BDD::Cucumber::Model::Document'] );

=head2 background

The L<Test::BDD::Cucumber::Model::Scenario> object that was marked as the
background section.

=cut

has 'background' =>
  ( is => 'rw', isa => InstanceOf['Test::BDD::Cucumber::Model::Scenario'] );

=head2 keyword_original

The keyword used in the input file; equivalent to specification
keyword C<Feature>.

=cut

has 'keyword_original' => ( is => 'rw', isa => Str );


=head2 scenarios

An arrayref of the L<Test::BDD::Cucumber::Model::Scenario> objects that
constitute the test.

=cut

has 'scenarios' => (
    is      => 'rw',
    isa     => ArrayRef[InstanceOf['Test::BDD::Cucumber::Model::Scenario']],
    default => sub { [] }
);

=head2 tags

Tags that the feature has been tagged with, and will pass on to its
Scenarios.

=cut

has 'tags' => ( is => 'rw', isa => ArrayRef[Str], default => sub { [] } );

=head2 language

Language the feature is written in. Defaults to 'en'.

=cut

has 'language' => (
    is      => 'rw',
    isa     => Str,
    default => sub { 'en' }
);

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
