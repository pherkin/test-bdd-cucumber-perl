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

subtest exit_code => sub {
    # Try to make some changes in the feature desription and expect a non-zero exit-code.
    my $tempdir = tempdir( CLEANUP => 1 );
    #diag $tempdir;
    dircopy "examples/digest", $tempdir;
    my $exit = system "$^X -Ilib bin/pherkin $tempdir";
    is $exit, 0, "exit code of broken Digest example";
    my $filename = "$tempdir/features/basic.feature";
    my $content = path($filename)->slurp_utf8;
    $content =~ s/When I've added "foo bar baz" to the object/When I have added "foo bar baz" to the object/;
    path($filename)->spew_utf8($content);

    my $new_exit = system "$^X -Ilib bin/pherkin $tempdir";
    isnt $new_exit, 0, "exit code of broken Digest example";
};


done_testing;
