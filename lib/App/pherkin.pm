package App::pherkin;

use strict;
use warnings;
use FindBin::libs;

=head1 NAME

App::pherkin - Run Cucumber tests from the command line

=head1 SYNOPSIS

 pherkin
 pherkin some/path/features/

=head1 DESCRIPTION

C<pherkin> will search the directory specified (or C<./features/>) for
feature files (any file matching C<*.feature>) and step definition files (any
file matching C<*_steps.pl>), loading the step definitions and then executing
the features.

Steps that pass will be printed in green, those that fail in red, and those
for which there is no step definition as yellow (for TODO).

If you'd like this to happen as part of your general test execution, consider
using L<t/900_run_features.thttps://github.com/sheriff/test-bdd-cucumber-perl/blob/master/t/900_run_features.t>
instead.

=cut

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TermColor;

sub run {
    my ( $class, @arguments ) = @_;
    my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
        $arguments[0] || './features/'
    );
    warn "No feature files found\n" unless @features;

    my $harness  = Test::BDD::Cucumber::Harness::TermColor->new();
    $executor->execute( $_, $harness ) for @features;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;