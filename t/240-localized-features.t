#!perl

use strict;
use warnings;

use Test::More;

use Test::File::ShareDir -share =>
  { -dist => { 'Test-BDD-Cucumber' => 'share' } };

use Test::BDD::Cucumber::Parser;

my $files = {
    en => 'examples/calculator/features/basic.feature',
    es => 'examples/calculator/features/basic.feature.es'
};

for my $language ( keys %$files ) {
    my $feature =
      Test::BDD::Cucumber::Parser->parse_file( $files->{$language} );

    isa_ok $feature, 'Test::BDD::Cucumber::Model::Feature',
      "feature in language '$language' can be parsed";
    is $feature->language, $language, 'feature language';
}

done_testing;
