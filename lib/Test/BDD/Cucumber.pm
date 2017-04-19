package Test::BDD::Cucumber;

use strict;
use warnings;
1;

# CODE ENDS

=head1 NAME

Test::BDD::Cucumber - Feature-complete Cucumber-style testing in Perl

=head1 SYNOPSIS

From the command line:

  # invoke all features at once
  $ pherkin t/bdd/

  # or just one set of features
  $ pherkin t/bdd/startup.feature

Or check the L<example test script integration|https://github.com/pjlsergeant/test-bdd-cucumber-perl/blob/master/t/900_run_cucumber_tests.t>

=head1 DESCRIPTION

A sane and complete Cucumber implementation in Perl

Behaviour of this module is similar to the I<real> Cucumber, the plan is
to move use the same parser and behaviour
L<See the logged issue|https://github.com/pjlsergeant/test-bdd-cucumber-perl/issues/73>.

=head1 QUICK LINKS

See this distribution: L<Cucumber on Perl on MetaCPAN|https://metacpan.org/release/Test-BDD-Cucumber>

=begin html

You can talk to the author(s) here: <a
href="https://gitter.im/pjlsergeant/test-bdd-cucumber-perl"><img
    src="https://badges.gitter.im/pjlsergeant/test-bdd-cucumber-perl.svg"
    alt="Chat on Gitter"
></a>

=end html

=head1 NEXT STEPS

If you are B<completely new to Cucumber>, you'd get a pretty overview from
reading our short and crunchy L<Tutorial|Test::BDD::Cucumber::Manual::Tutorial>.

If you B<already understand Cucumber>, and just want to get started then you
should read the L<Step-writing quick-start
guide|Test::BDD::Cucumber::Manual::Steps>, the documentation for our
command-line tool L<App::pherkin>, and L<How to integrate with
Test::Builder|Test::BDD::Cucumber::Manual::Integration>.

If you B<want to extend or integrated Test::BDD::Cucumber> then you'd probably
be more interested in our L<Architecture
overview|Test::BDD::Cucumber::Manual::Architecture>.

=head1 TEN SECOND GUIDE TO USING THIS IN YOUR CI ENVIRONMENT

Don't use the command-line tool, L<App::pherkin>, for integration in your
CI environment. Instead, look at the L<How to integrate with
Test::Builder|Test::BDD::Cucumber::Manual::Integration> document.

=head1 BUGS, MISSING, AND LIMITATIONS

For current bugs, check the issue tracer at GitHub:

  L<https://github.com/pjlsergeant/test-bdd-cucumber-perl/issues>

Since Test::BDD::Cucumber uses its own parser, differences probably exist
in the intepretation of feature files when comparing to Cucumber.

=head1 CODE

On Github, of course: L<https://github.com/pjlsergeant/test-bdd-cucumber-perl>.

=head1 AUTHORS

Peter Sergeant C<pete@clueball.com>

Erik Huelsmann C<ehuels@gmail.com>

Ben Rodgers C<ben@bdr.org>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut
