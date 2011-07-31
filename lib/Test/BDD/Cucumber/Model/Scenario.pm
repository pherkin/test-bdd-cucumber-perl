package Test::BDD::Cucumber::Model::Scenario;

use Moose;

has 'name'       => ( is => 'rw', isa => 'Str' );
has 'steps'      => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Cucumber::Model::Step]', default => sub {[]} );
has 'data'       => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub {[]} );
has 'background' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'line'       => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Line' );

1;