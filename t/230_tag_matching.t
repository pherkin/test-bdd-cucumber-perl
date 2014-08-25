#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Model::Scenario;
use Test::BDD::Cucumber::Model::TagSpec;

my @scenarios = map {
    my @atoms = @$_;
    Test::BDD::Cucumber::Model::Scenario->new(
        {
            name => shift(@atoms),
            tags => \@atoms
        }
    );
  } (
    [ mercury => qw/all inner / ],
    [ venus   => qw/all inner / ],
    [ earth   => qw/all inner life home/ ],
    [ mars    => qw/all inner life red / ],
    [ jupiter => qw/all outer gas red / ],
    [ saturn  => qw/all outer gas/ ],
    [ uranus  => qw/all outer gas/ ],
    [ nepture => qw/all outer gas/ ],
    [ pluto   => qw/all outer fake/ ],
  );

for my $test (
    [ "Lifers and Fakers", [ or => 'life', 'fake' ], qw/ earth mars pluto /, ],
    [
        "Lifeless inner",
        [ and => [ not => 'life' ], 'inner' ],
        qw/ mercury venus /,
    ],
    [
        "Home or Red, Inner",
        [ and => 'inner', [ or => 'home', 'red' ] ],
        qw/ earth mars /,
    ],
    [
        "Home or Not Red, Inner",
        [ and => 'inner', [ or => 'home', [ not => 'red' ] ] ],
        qw/ mercury venus earth /,
    ]
  )
{
    my ( $name, $search, @result ) = @$test;
    my $tag_spec =
      Test::BDD::Cucumber::Model::TagSpec->new( { tags => $search } );
    my @matches = map { $_->name } $tag_spec->filter(@scenarios);
    is_deeply( \@matches, \@result, "Matched scenario: $name" );
}

done_testing();
