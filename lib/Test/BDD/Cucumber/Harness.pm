package Test::BDD::Cucumber::Harness;

use strict;
use warnings;
use Moose;

sub feature {
    my ( $self, $feature ) = @_;
}

sub feature_done {
    my ( $self, $feature ) = @_;
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
}

sub scenario_done {
    my ( $self, $scenario, $dataset ) = @_;
}

sub step {
    my ( $self, $context ) = @_;
}

sub step_done {
    my ($self, $context, $tb_hash) = @_;

}

1;