package Test::BDD::Model::Feature;

use Moose;

has 'name'         => ( is => 'rw', isa => 'Str' );
has 'name_line'    => ( is => 'rw', isa => 'Test::BDD::Model::Line' );
has 'satisfaction' => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Model::Line]',
	default => sub {[]});

has 'document'   => ( is => 'rw', isa => 'Test::BDD::Model::Document' );
has 'background' => ( is => 'rw', isa => 'Test::BDD::Model::Scenario' );
has 'scenarios'  => ( is => 'rw', isa => 'ArrayRef[Test::BDD::Model::Scenario]',
	default => sub {[]} );

1;