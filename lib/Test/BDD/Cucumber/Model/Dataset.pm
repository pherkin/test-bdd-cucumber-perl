package Test::BDD::Cucumber::Model::Dataset;

use Moo;
use Types::Standard qw( Str ArrayRef HashRef Bool InstanceOf );

=head1 NAME

Test::BDD::Cucumber::Model::Scenario - Model to represent a scenario

=head1 DESCRIPTION

Model to represent a scenario

=head1 ATTRIBUTES

=head2 name

The text after the C<Examples:> keyword

=cut

has 'name' => ( is => 'rw', isa => Str );


=head2 description

The text between the Scenario line and the first step line

=cut

has 'description' => (
    is      => 'rw',
    isa     => ArrayRef[InstanceOf['Test::BDD::Cucumber::Model::Line']],
    default => sub { [] },
    );

=head2 data

Scenario-related data table, as an arrayref of hashrefs

=cut

has 'data' => ( is => 'rw', isa => ArrayRef[HashRef], default => sub { [] } );

=head2 line

A L<Test::BDD::Cucumber::Model::Line> object corresponding to the line where
the C<Scenario> keyword is.

=cut

has 'line' => ( is => 'rw', isa => InstanceOf['Test::BDD::Cucumber::Model::Line'] );

=head2 tags

Tags that the scenario has been tagged with, and has inherited from its
feature.

=cut

has 'tags' => ( is => 'rw', isa => ArrayRef[Str], default => sub { [] } );

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2021, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
