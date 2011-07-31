package Test::BDD::Cucumber::Model::Step;

use Moose;

has 'text' => ( is => 'rw', isa => 'Str' );
has 'verb' => ( is => 'rw', isa => 'Str' );
has 'verb_original' => ( is => 'rw', isa => 'Str' );
has 'line' => ( is => 'rw', isa => 'Test::BDD::Cucumber::Model::Line' );
has 'data' => ( is => 'rw' );

1;