#!perl

use strict;
use warnings;

use lib 't/lib/';

use Test::More;
use Test::Differences;
use Test::DumpFeature;
use Test::BDD::Cucumber::Parser;
use YAML;
use File::Find::Rule;

my @files = @ARGV;
@files =
  File::Find::Rule->file()->name('*.feature_corpus')->in('t/auto_corpus/')
  unless @files;

for my $file (@files) {
    my $file_data;

    open(my $in, '<', $file) or die $?;
    binmode $in, 'utf8';
    {
        local $/;
        $file_data = <$in>;
    }
    my ( $feature, $yaml ) = split( /----------DIVIDER----------/, $file_data );
    my $expected = Load($yaml);
    my $actual   = Test::DumpFeature::dump_feature(
        Test::BDD::Cucumber::Parser->parse_string($feature) );

    is_deeply( $actual, $expected, "$file matches" )
      || eq_or_diff( $actual, $expected );
}

done_testing();
