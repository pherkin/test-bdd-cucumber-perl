#!perl

use strict;
use warnings;
use Test::More;
use Test::BDD::Cucumber::I18n qw(languages);

my @languages = languages();
ok scalar @languages, 'languages can be retrieved';

done_testing;
