package Test::BDD::StepContext;

use Moose;

has 'data'     => ( is => 'ro' );
has 'stash'    => ( is => 'ro', required => 1, isa => 'HashRef' );
has 'feature'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Model::Feature' );
has 'scenario' => ( is => 'ro', required => 1, isa => 'Test::BDD::Model::Scenario' );
has 'step'     => ( is => 'ro', required => 1, isa => 'Test::BDD::Model::Step' );
has 'verb'     => ( is => 'ro', required => 1, isa => 'Str' );
has 'text'     => ( is => 'ro', required => 1, isa => 'Str' );
has 'harness'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Harness' );
has 'matches'  => ( is => 'rw', isa => 'ArrayRef' );
has 'status'   => ( is => 'rw', isa => 'Test::BDD::Harness::Step' );

1;
