#!perl

use strict;
use warnings;
use FindBin::libs;

use Test::More;
use Test::DumpFeature;
use Test::BDD::Cucumber::Parser;
use YAML;
use File::Slurp;

my $file_data = read_file( $ARGV[0] );

my $feature      = Test::BDD::Cucumber::Parser->parse_string($file_data);
my $feature_hash = Test::DumpFeature::dump_feature($feature);

print $file_data . "\n----------DIVIDER----------\n" . Dump($feature_hash);
