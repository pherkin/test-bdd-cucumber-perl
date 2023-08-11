use v5.14;
use warnings;

package Test::BDD::Cucumber::I18n;

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::I18N - Internationalization

=head1 DESCRIPTION

Internationalization of feature files and step definitions.

=head1 SYNOPSIS

  use Test::BDD::Cucumber::I18n
      qw(languages has_language langdef);

  # get codes of supported languages
  my @supported_languages = languages();

  # look up if a language is supported
  my $language_is_supported = has_language('de');

  # get definition of a language
  my $langdef = langdef('de');

  # get readable keyword definitions
  my $string = readable_keywords

=cut

use utf8;

use base 'Exporter';

our @EXPORT_OK =
  qw(languages langdef has_language readable_keywords keyword_to_subname);

use Test::BDD::Cucumber::I18N::Data;

=head1 METHODS

=head2 languages

Get codes of supported languages.

=cut

sub languages {
    return sort keys %Test::BDD::Cucumber::I18N::Data::languages;
}

=head2 has_language($language)

Check if a language is supported.  Takes as argument the language
abbreviation defined in C<share/i18n.json>.

=cut

sub has_language {
    my ($language) = @_;
    return exists $Test::BDD::Cucumber::I18N::Data::languages{$language};
}

=head2 langdef($language)

Get definition of a language.  Takes as argument the language abbreviation
defined in C<share/i18n.json>.

=cut

sub langdef {
    my ($language) = @_;

    return unless has_language($language);
    return $Test::BDD::Cucumber::I18N::Data::languages{$language};
}

=head2 readable_keywords($string, $transform)

Get readable keyword definitions.

=cut

sub readable_keywords {
    my ( $string, $transform ) = @_;

    my @keywords = split( /\|/, $string );

    @keywords = map { $transform->($_) } @keywords if $transform;

    return join( ', ', map { '"' . $_ . '"' } @keywords );
}

=head2 keyword_to_subname

Return a keyword into a subname with non-word characters removed.

=cut

sub keyword_to_subname {
    my ($word) = @_;

    # remove non-word characters so we have a decent sub name
    $word =~ s{[^\p{Word}]}{}g;

    return $word;
}

=head1 LANGUAGES

Languages are defined in L<Test::BDD::Cucumber::I18N::Data>, and have been
lifted from the Gherkin distribution.

=head1 AUTHOR

Gregor Goldbach C<glauschwuffel@nomaden.org>
(based on the works of Pablo Duboue)

=head1 LICENSE

  Copyright 2019-2023, Erik Huelsmann
  Copyright 2014-2019, Gregor Goldbach; Licensed under the same terms as Perl

=cut

1;
