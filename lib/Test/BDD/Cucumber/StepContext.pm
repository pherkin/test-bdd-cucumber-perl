package Test::BDD::Cucumber::StepContext;

use Moose;

has 'data'     => ( is => 'ro' );
has 'stash'    => ( is => 'ro', required => 1, isa => 'HashRef' );
has 'feature'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Feature' );
has 'scenario' => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Scenario' );
has 'step'     => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Model::Step' );
has 'verb'     => ( is => 'ro', required => 1, isa => 'Str' );
has 'text'     => ( is => 'ro', required => 1, isa => 'Str' );
has 'harness'  => ( is => 'ro', required => 1, isa => 'Test::BDD::Cucumber::Harness' );
has 'matches'  => ( is => 'rw', isa => 'ArrayRef' );
has 'status'   => ( is => 'rw', isa => 'Test::BDD::Cucumber::Harness::Step' );

1;
