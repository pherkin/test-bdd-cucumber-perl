#!perl

use strict;
use warnings;

use Test::More;
use FindBin::libs;
use App::pherkin;
use Data::Dumper;

for my $test (
    [ 'Single tag: -t @cow', ['@cow'], [ and => [ or => 'cow' ] ] ],
    [
        'Two AND tags: -t @cow -t @blue',
        [ '@cow', '@blue' ],
        [ and => [ or => 'cow' ], [ or => 'blue' ] ]
    ],
    [
        'Two OR tags: -t @cow,@blue',
        ['@cow,@blue'],
        [ and => [ or => 'cow', 'blue' ] ]
    ],
    [
        'Two OR, one AND: -t @cow,@blue -t @moo',
        [ '@cow,@blue', '@moo' ],
        [ and => [ or => 'cow', 'blue' ], [ or => 'moo' ] ]
    ],
    [
        'Negated tag: -t ~@cow',
        ['~@cow'],
        [ and => [ or => [ not => 'cow' ] ] ]
    ],
    [
        'Negated with OR tag: -t ~@cow,@fish',
        ['~@cow,@fish'],
        [ and => [ or => [ not => 'cow' ], 'fish' ] ]
    ],
    [
        'Negated with AND tag: -t ~@cow -t @fish',
        [ '~@cow', '@fish' ],
        [ and => [ or => [ not => 'cow' ] ], [ or => 'fish' ] ]
    ],
    [
        'Two negated: -t ~@cow,~@fish',
        ['~@cow,~@fish'],
        [ and => [ or => [ not => 'cow' ], [ not => 'fish' ] ] ]
    ],
  )
{
    my ( $name, $tags, $result ) = @$test;
    my $tag_out = App::pherkin->new()->_process_tags( @{$tags} );
    is_deeply( $tag_out, $result, "Tags: $name" );
}

done_testing();
