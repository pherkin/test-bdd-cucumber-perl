package Test::BDD::Cucumber;

use strict;
use warnings;
1;

# CODE ENDS

=head1 NAME

Test::BDD::Cucumber - Feature-complete Cucumber-style testing in Perl

=head1 SYNOPSIS


   # Driving tests using the 'pherkin' binary that comes with the distribution
   $ pherkin -l -b t/

   # Or choose a subset of tests to be run by selecting all scenarios tagged 'slow'
   $ pherkin -l -b --tags @slow t/

   # Or all those /not/ tagged 'slow'
   $ pherkin -l -b --tags ~@slow


   # Driving tests using 'prove' integration
   $ prove --source Feature --ext=.feature t/

   # Driving parallel tests using 'prove'
   $ prove --source Feature -j 9 --ext=.feature t/


=head1 DESCRIPTION

A sane and complete Cucumber implementation in Perl

Behaviour of this module is similar to that, but sometimes different from
the I<real> Cucumber, the plan is to move use the same parser and behaviour
L<See the logged issue|https://github.com/pherkin/test-bdd-cucumber-perl/issues/73>.

The implementation supports the following Gherkin keywords in feature files:
C<Feature>, C<Scenario>, C<Scenario Outline>, C<Examples>, C<Given>, C<When>,
C<Then>, C<And> and C<But>. Additionally, C<Scenario> can be used with C<Examples>.
This best maps to L<Gherkin version 6.0.13|https://github.com/cucumber/cucumber/blob/master/gherkin/CHANGELOG.md#6013---2018-09-25>,
but without support for its new C<Rule> and C<Example> keywords.

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

  L<https://github.com/pherkin/test-bdd-cucumber-perl/issues>

Since Test::BDD::Cucumber uses its own parser, differences probably exist
in the intepretation of feature files when comparing to Cucumber.

=head1 CODE

On Github, of course: L<https://github.com/pherkin/test-bdd-cucumber-perl>.

=head1 AUTHORS

Peter Sergeant C<pete@clueball.com>

Erik Huelsmann C<ehuels@gmail.com>

Ben Rodgers C<ben@bdr.org>

=head1 LICENSE

Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut
