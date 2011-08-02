package Test::BDD::Cucumber;

=head1 NAME

Test::BDD::Cucumber - Feature-complete Cucumber-style testing in Perl

=head1 DESCRIPTION

A sane and complete Cucumber implementation in Perl

=head1 WARNING

This is beta software, at best. The interface is unlikely to undergo major
incompatible changes, but it's certainly possible. Do have a read of the
B<Bugs and Missing> section below so you're not surprised when these things
don't work.

=head1 NEXT STEPS

If you are B<completely new to Cucumber>, you'd get a pretty overview from
reading our short and crunchy L<Tutorial|Test::BDD::Cucumber::Manual::Tutorial>.

If you B<already understand Cucumber>, and just want to get started then you
should read the L<Step-writing quick-start
guide|Test::BDD::Cucumber::Manual::Steps>, the documentation for our
command-line tool L<App::Pherkin>, and L<How to integrate with
Test::Builder|Test::BDD::Cucumber::Manual::Integration>.

If you B<want to extend or integrated Test::BDD::Cucumber> then you'd probably
be more interested in our L<Architecture
overview|Test::BDD::Cucumber::Manual::Architecture>.

=head1 BUGS AND MISSING

The following things do not work in this release, although support is planned
in the very near future:

=over 4

=item * Tags

=item * Localization

=item * Step Argument Transforms

=item * Quoting in tables is broken

=item * Placeholders in pystrings is broken

=back

=head1 CODE

On Github, of course: L<https://github.com/sheriff/test-bdd-cucumber-perl>.

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;