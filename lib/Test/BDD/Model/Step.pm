package Test::BDD::Model::Step;

use Moose;

has 'text' => ( is => 'rw', isa => 'Str' );
has 'verb' => ( is => 'rw', isa => 'Str' );
has 'verb_original' => ( is => 'rw', isa => 'Str' );
has 'line' => ( is => 'rw', isa => 'Test::BDD::Model::Line' );
has 'data' => ( is => 'rw' );

1;