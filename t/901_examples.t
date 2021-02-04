#!perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);
use Path::Tiny qw(path);

my $dir = 'examples';

subtest examples => sub {
    my @examples = grep { -d $_ } glob("$dir/*");
    #diag explain \@examples;

    for my $example (@examples) {
        my $exit = system "$^X -Ilib bin/pherkin $example";
        is $exit, 0, "exit code of $example";
    }
};

subtest exit_code_incorrect_test_case => sub {
    # Try to make some changes in the feature description and expect a non-zero exit-code when --strict is provided
    my $tempdir = tempdir( CLEANUP => 1 );
    #diag $tempdir;
    dircopy "examples/digest", $tempdir;
    my $filename = "$tempdir/features/basic.feature";
    {
        my $exit = system "$^X -Ilib bin/pherkin $tempdir";
        is $exit, 0, "exit code of broken Digest example";
    }

    my $content = path($filename)->slurp_utf8;
    $content =~ s/When I've added "foo bar baz" to the object/When I have added "foo bar baz" to the object/;
    path($filename)->spew_utf8($content);

    {
        my $exit = system "$^X -Ilib bin/pherkin $tempdir";
        is $exit, 0, "exit code of broken Digest example";
    }

    {
        my $exit = system "$^X -Ilib bin/pherkin --strict $tempdir";
        is $exit, 256, "exit code of broken Digest example";
    }
};

subtest exit_code_for_bad_results => sub {
    my $tempdir = tempdir( CLEANUP => 1 );

    dircopy "examples/digest", $tempdir;
    my $filename = "$tempdir/features/basic.feature";

    my $content = path($filename)->slurp_utf8;
    $content =~ s/75ad9f578e43b863590fae52d5d19ce6/somethingelse/;
    path($filename)->spew_utf8($content);

    {
        my $exit = system "$^X -Ilib bin/pherkin $tempdir";
        is $exit, 512, "exit code of broken Digest example";
    }
};



done_testing;
