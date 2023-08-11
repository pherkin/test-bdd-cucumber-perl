#!perl

use strict;
use warnings;

use JSON::MaybeXS 'decode_json';
use Test::More;


use App::pherkin;

do {
    my $output = '';
    open my $fh, '>', \$output;
    local *STDOUT = $fh;

    my $pherkin = App::pherkin->new;
    $pherkin->run('-oJSON', '--tags', '@include',
                  't/cucumber_tagging_feature/tagged.feature');
    ok $output, 'Have JSON output';
    my $data = decode_json($output);
    my $feature = pop @{ $data };

    is $feature->{keyword}, 'Feature';
    is($_->{type}, 'scenario') for (@{ $feature->{elements} });
    is($_->{keyword}, 'Scenario') for (@{ $feature->{elements} });
    is(scalar(@{ $feature->{elements} }), 1);
};


do {
    my $output = '';
    open my $fh, '>', \$output;
    local *STDOUT = $fh;

    my $pherkin = App::pherkin->new;
    $pherkin->run('-oJSON', '--tags', 'not @exclude',
                  't/cucumber_tagging_feature/tagged.feature');
    ok $output, 'Have JSON output';
    my $data = decode_json($output);
    my $feature = pop @{ $data };

    is $feature->{keyword}, 'Feature';
    is($_->{type}, 'scenario') for (@{ $feature->{elements} });
    is($_->{keyword}, 'Scenario') for (@{ $feature->{elements} });
    is(scalar(@{ $feature->{elements} }), 2);
};

do {
    my $output = '';
    open my $fh, '>', \$output;
    local *STDOUT = $fh;

    my $pherkin = App::pherkin->new;
    $pherkin->run('-oJSON', '--tags', '@include or @exclude',
                  't/cucumber_tagging_feature/tagged.feature');
    ok $output, 'Have JSON output';
    my $data = decode_json($output);
    my $feature = pop @{ $data };

    is $feature->{keyword}, 'Feature';
    is($_->{type}, 'scenario') for (@{ $feature->{elements} });
    is($_->{keyword}, 'Scenario') for (@{ $feature->{elements} });
    is(scalar(@{ $feature->{elements} }), 2);
};

do {
    my $output = '';
    open my $fh, '>', \$output;
    local *STDOUT = $fh;

    my $pherkin = App::pherkin->new;
    $pherkin->run('-oJSON', '--tags', 'not @include and not @exclude',
                  't/cucumber_tagging_feature/tagged.feature');
    ok $output, 'Have JSON output';
    my $data = decode_json($output);
    my $feature = pop @{ $data };

    is $feature->{keyword}, 'Feature';
    is($_->{type}, 'scenario') for (@{ $feature->{elements} });
    is($_->{keyword}, 'Scenario') for (@{ $feature->{elements} });
    is(scalar(@{ $feature->{elements} }), 1);
};

done_testing;
