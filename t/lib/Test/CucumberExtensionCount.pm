#!perl

package Test::CucumberExtensionCount;

use Moo;
use Types::Standard qw( HashRef );
use Test::BDD::Cucumber::Extension;
extends 'Test::BDD::Cucumber::Extension';

has counts => ( is => 'ro', isa => HashRef, default => sub { {} } );

sub step_directories {
    return ['extension_steps/'];
}

sub pre_feature  { $_[0]->counts->{pre_feature}++; }
sub post_feature { $_[0]->counts->{post_feature}++; }

sub pre_scenario  { $_[0]->counts->{pre_scenario}++; }
sub post_scenario { $_[0]->counts->{post_scenario}++; }

sub pre_step  { $_[0]->counts->{pre_step}++; }
sub post_step { $_[0]->counts->{post_step}++; }

__PACKAGE__->meta->make_immutable;

1;
