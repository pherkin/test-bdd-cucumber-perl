package Test::BDD::Cucumber;

=head1 NAME

Test::BDD::Cucumber - Feature-complete Cucumber-style testing in Perl

=head1 DESCRIPTION

A sane and complete Cucumber implementation in Perl

=head1 QUICK LINKS

L<Cucumber on Perl on MetaCPAN|https://metacpan.org/release/Test-BDD-Cucumber>

=head1 WARNING

This is beta software, at best. The interface is unlikely to undergo major
incompatible changes, but it's certainly possible. Do have a read of the
B<Bugs and Missing> section below so you're not surprised when these things
don't work.

In almost all cases, where the behaviour of this module is different from
the I<real> Cucumber, the plan is to move it to be more similar to that.

The idea is that the first 1.0 release will be the first production release and
before that, you're on your own. There are many things still to add, but B<I'm>
using it to do Real Things already.

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

=head1 BUGS, MISSING, AND LIMITATIONS

The following things do not work in this release, although support is planned
in the very near future:

=over 4

=item * Tags

=item * Localization

=item * Step Argument Transforms

=item * Quoting in tables is broken

=item * Placeholders in pystrings is broken

=item * Explicit Step Outline notation doesn't work (although step outlines are explictly supported)

=item * Unicode support is probably a bit ropey

=item * Pherkin isn't really fit for purpose yet

=back

=head1 CODE

On Github, of course: L<https://github.com/sheriff/test-bdd-cucumber-perl>.

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
