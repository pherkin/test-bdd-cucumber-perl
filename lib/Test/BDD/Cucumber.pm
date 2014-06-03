package Test::BDD::Cucumber;

=head1 NAME

Test::BDD::Cucumber - Feature-complete Cucumber-style testing in Perl

=head1 DESCRIPTION

A sane and complete Cucumber implementation in Perl

=head1 QUICK LINKS

L<Cucumber on Perl on MetaCPAN|https://metacpan.org/release/Test-BDD-Cucumber>

=head1 WARNING

Do have a read of the B<Bugs and Missing> section below so you're not surprised
when things don't work.

In almost all cases, where the behaviour of this module is different from
the I<real> Cucumber, the plan is to move it to be more similar to that.

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

Don't use the command-line tool, L<App::pherkin>. Instead, look at the L<How to integrate with
Test::Builder|Test::BDD::Cucumber::Manual::Integration> document.

=head1 BUGS, MISSING, AND LIMITATIONS

The following things do not work in this release, although support is planned
in the very near future:

=over 4

=item * Quoting in tables is broken

=item * Placeholders in pystrings is broken

=item * Explicit Step Outline notation doesn't work (although step outlines are explicitly supported)

=item * Pherkin isn't really fit for purpose yet

=back

=head1 CODE

On Github, of course: L<https://github.com/sheriff/test-bdd-cucumber-perl>.

=head1 AUTHORS

Peter Sergeant C<pete@clueball.com>

Ben Rodgers C<ben@bdr.org>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
