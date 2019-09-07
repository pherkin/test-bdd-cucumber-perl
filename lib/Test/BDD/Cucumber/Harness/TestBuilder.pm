package Test::BDD::Cucumber::Harness::TestBuilder;

=head1 NAME

Test::BDD::Cucumber::Harness::TestBuilder - Temporary redirector to TAP harness

=head1 DESCRIPTION


=cut

use Test::BDD::Cucumber::Harness::TAP;

use Moo;
extends 'Test::BDD::Cucumber::Harness::TAP';

warn __PACKAGE__ . ' has been renamed to Test::BDD::Cucumber::Harness::TAP; TestBuilder will be removed in 1.0';

1;
