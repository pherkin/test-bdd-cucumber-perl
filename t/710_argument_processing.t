#!perl

use strict;
use warnings;

use Test::More;
use App::pherkin;
use Data::Dumper;

for my $test (
    [ 'example config file (default profile)',
      [ '-c', 'examples/pherkin.yml', '-p', 'default' ],
      [ [
         '/usr/share/perl/5.14.2/Test/BDD/Plugin/steps',
         '~/your-project/steps'
        ],
        [ 'and', [ 'or', 'tag1', 'tag2', 'tag3' ],
        ],
      ]
    ],
  )
{
    my ( $name, $arguments, $result ) = @$test;
    my $app = App::pherkin->new();
    $app->_process_arguments( @$arguments );
    my $out = [ $app->step_paths, $app->tag_scheme ];
    is_deeply( $out, $result, "Arguments: $name" );
}

done_testing();
