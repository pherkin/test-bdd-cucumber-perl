package Test::BDD::Cucumber::Model::Feature;

use Moose;

has 'name'         => ( is => 'rw', isa => 'Str' );
has 'name_line'    => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Line' );
has 'satisfaction' => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Cucumber::Model::Line]',
	default => sub {[]});

has 'document'   => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Document' );
has 'scenarios'  => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Cucumber::Model::Scenario]',
	default => sub {[]} );

1;