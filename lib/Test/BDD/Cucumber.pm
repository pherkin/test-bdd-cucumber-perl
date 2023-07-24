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

   # Fail on missing steps (by default prints as orange output and succeeds tests)
   $ pherkin -l -b --strict t/


   # Driving tests using 'prove' integration
   $ prove --source Feature --ext=.feature examples/

   # Driving parallel tests using 'prove'
   $ prove -r --source Feature -j 9 --ext=.feature t/


=head1 DESCRIPTION

Cucumber for Perl, integrated with L<Test2>, L<Test::More> and L<prove>.

The implementation supports the following Gherkin keywords in feature files:
C<Feature>, C<Scenario>, C<Scenario Outline>, C<Examples>, C<Given>, C<When>,
C<Then>, C<And> and C<But>. Additionally, C<Scenario> can be used as a synonym
for C<Scenario Outline> (with C<Examples>). This best maps to
L<Gherkin version 6.0.13|https://github.com/cucumber/cucumber/blob/master/gherkin/CHANGELOG.md#6013---2018-09-25>,
but without support for its new C<Rule> and C<Example> keywords.

This implementation supports the same languages as Gherkin 15.0.0 - that is, it
supports exactly the same translated keywords.

Behaviour of this module is similar to that, but sometimes different from
the I<real> Cucumber, the plan is to move use the same parser and behaviour.


=head1 GETTING STARTED

This module comes with a few introductory tutorials.

=over 4

=item * L<A Cucumber feature writing tutorial|Test::BDD::Cucumber::Manual::Tutorial>

for those new to Cucumber and BDD testing

=item * L<A Step writing tutorial|Test::BDD::Cucumber::Manual::Steps>

to get you started writing the code run for each C<Given>, C<Then>, C<When> step

=item * L<A guide on integrating with your test suite|Test::BDD::Cucumber::Manual::Integration>

=item * L<An architecture overview|Test::BDD::Cucumber::Manual::Architecture>

for those who want to extend or hook into feature file execution

=item * Documentation of the command-line tool L<App::pherkin>

=back

=begin html

If you have problems getting started, you can talk to the author(s) here: <a
href="https://gitter.im/pjlsergeant/test-bdd-cucumber-perl"><img
    src="https://badges.gitter.im/pjlsergeant/test-bdd-cucumber-perl.svg"
    alt="Chat on Gitter"
></a>

=end html

=head1 BUGS AND LIMITATIONS

For current bugs, check the issue tracer at GitHub:
L<https://github.com/pherkin/test-bdd-cucumber-perl/issues>

One thing need specific mentioning:

=over 4

=item * Due to the use of its own parser, differences probably exist
in the interpretation of feature files when comparing to Cucumber.

Also L<see the issue|https://github.com/pherkin/test-bdd-cucumber-perl/issues/73> for
tracking this topic.

=back

=head1 PROJECT RESOURCES

=over 4

=item * Source code repository at L<https://github.com/pherkin/test-bdd-cucumber-perl>

=item * Bug tracker at L<https://github.com/pherkin/test-bdd-cucumber-perl/issues>

=item * Mailing list at L<mailto:perl-pherkin@googlegroups.com>

=item * Chat (Gitter) at L<https://gitter.im/pjlsergeant/test-bdd-cucumber-perl>

=item * Chat (IRC) at L<irc://irc.freenode.net/#perl>

=item * Website at L<https://pherkin.pm>

=back

=head1 SEE ALSO

L<Gherkin> - A Gherkin parser and compiler

=head1 AUTHORS

Peter Sergeant C<pete@clueball.com>

Erik Huelsmann C<ehuels@gmail.com>

Ben Rodgers C<ben@bdr.org>

=head1 LICENSE

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut
