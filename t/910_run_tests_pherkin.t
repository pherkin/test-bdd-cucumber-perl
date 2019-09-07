#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use App::pherkin;
use Test::CucumberExtensionMetadataVerify;

my $pherkin = App::pherkin->new;
push @{$pherkin->extensions}, Test::CucumberExtensionMetadataVerify->new;
subtest 'Run pherkin in match-only mode', sub {
    $pherkin->run('-oTAP', '-m', 't/pherkin/match-only/');
};

done_testing;
