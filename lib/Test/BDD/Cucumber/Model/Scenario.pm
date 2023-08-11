use v5.14;
use warnings;

package Test::BDD::Cucumber::Model::Scenario;

use Moo;
use Types::Standard qw( Str ArrayRef HashRef Bool InstanceOf );

use Carp;

=head1 NAME

Test::BDD::Cucumber::Model::Scenario - Model to represent a scenario

=head1 DESCRIPTION

Model to represent a scenario

=head1 ATTRIBUTES

=head2 name

The text after the C<Scenario:> keyword

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

=head2 steps

The associated L<Test:BDD::Cucumber::Model::Step> objects

=cut

has 'steps' => (
    is      => 'rw',
    isa     => ArrayRef[InstanceOf['Test::BDD::Cucumber::Model::Step']],
    default => sub { [] }
);

=head2 datasets

The dataset(s) associated with a scenario.

=cut

has 'datasets' => (
    is      => 'rw',
    isa     => ArrayRef[InstanceOf['Test::BDD::Cucumber::Model::Dataset']],
    default => sub { [] }
);

=head2 background

Boolean flag to mark whether this was the background section

=cut

has 'background' => ( is => 'rw', isa => Bool, default => 0 );

=head2 keyword

=head2 keyword_original

The keyword used in the input file (C<keyword_original>) and its specification
equivalent (C<keyword>) used to start this scenario. (I.e. C<Background>,
C<Scenario> and C<Scenario Outiline>.)

=cut

has 'keyword'          => ( is => 'rw', isa => Str );
has 'keyword_original' => ( is => 'rw', isa => Str );


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

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
