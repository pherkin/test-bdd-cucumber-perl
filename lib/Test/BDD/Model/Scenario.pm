package Test::BDD::Model::Scenario;

use Moose;

has 'title'      => ( is => 'rw', isa => 'Str' );
has 'steps'      => ( is => 'rw', isa => 'Test::BDD::Model::Step' );
has 'dataset'    => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub {[]} );
has 'background' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'line'       => ( is => 'rw', isa => 'Test::BDD::Model::Line' );

1;