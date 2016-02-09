#!perl

package Test::CucumberExtensionPush;

use Moose;
use Test::BDD::Cucumber::Extension;
extends 'Test::BDD::Cucumber::Extension';

has id => (is => 'ro');
has hash => ( is => 'ro', isa => 'HashRef', default => sub { {} } );


sub step_directories {
    return [ 'extension_steps/' ];
}

sub pre_feature { push @{$_[0]->hash->{pre_feature}}, $_[0]->id; }
sub post_feature { push @{$_[0]->hash->{post_feature}}, $_[0]->id; }

sub pre_scenario { push @{$_[0]->hash->{pre_scenario}}, $_[0]->id; }
sub post_scenario { push @{$_[0]->hash->{post_scenario}}, $_[0]->id; }

sub pre_step { push @{$_[0]->hash->{pre_step}}, $_[0]->id; }
sub post_step { push @{$_[0]->hash->{post_step}}, $_[0]->id; }

__PACKAGE__->meta->make_immutable;

1;
