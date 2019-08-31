
use strict;
use warnings;

use Test::BDD::Cucumber::StepFile;


Given qr/^\Qa step with step function that calls die()\E$/, sub {
    die "This step function calls die()";
};

When qr/^\Qthere are further steps with associated step functions\E$/, sub {
};

Then qr/^\QI expect all steps to be matched\E$/, { 'meta' => 'data' }, sub {
};

