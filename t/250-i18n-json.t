#!perl

use strict;
use warnings;

use Test::More;

use Test::File::ShareDir
  -share => {
    -dist   => { 'Test-BDD-Cucumber'    => 'share' }
  };
# include it *after* Test::File::ShareDir since we need the share dir
use Test::BDD::Cucumber::I18n qw(languages);

my @languages = languages();
ok scalar @languages, 'languages can be retrieved';

done_testing;
