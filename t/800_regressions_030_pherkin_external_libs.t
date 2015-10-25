#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::BDD::Cucumber::Harness::Data;
use App::pherkin;

for my $test (
    [ '-l', ['lib'], '-l adds lib' ],
    [ '-b', [ 'blib/lib', 'blib/arch' ], '-b adds blib/lib and blib/arch' ],
    [   '-l -b',
        [ 'blib/lib', 'blib/arch', 'lib' ],
        '-l -lb adds lib, blib/lib and blib/arch'
    ],
    [ '-I foo -I bar', [ 'foo', 'bar' ], '-I accepts multiple arguments' ],
    [   '-I foo -l -I bar', [ 'lib', 'foo', 'bar' ],
        '-I and -l work together'
    ],
    )
{
    my ( $flags, $expected, $name ) = @$test;
    local @INC = ();
    my $p = App::pherkin->new();
    $p->_process_arguments( split( / /, '-o Data ' . $flags ) );
    is_deeply( \@INC, $expected, $name );
}
