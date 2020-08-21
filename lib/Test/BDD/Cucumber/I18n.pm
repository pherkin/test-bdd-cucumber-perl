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

use strict;
use warnings;
use utf8;

use base 'Exporter';

our @EXPORT_OK =
  qw(languages langdef has_language readable_keywords keyword_to_subname);

use Test::BDD::Cucumber::I18N::Data;

my $langdefs = _initialize_language_definitions_from_shared_json_file();

sub _initialize_language_definitions_from_shared_json_file {

    # Parse keywords hash for all supported languages from the JSON file
    my $langdefs = Test::BDD::Cucumber::I18N::Data::language_definitions();

    # strip asterisks from the keyword definitions since they don't work yet
    for my $language ( keys %$langdefs ) {
        my $langdef = $langdefs->{$language};
        for my $key ( keys %$langdef ) {
            $langdef->{$key} =~ s{[*]\s*[|]}{};
        }
    }

    return $langdefs;
}

=head1 METHODS

=head2 languages

Get codes of supported languages.

=cut

sub languages {
    return keys %$langdefs;
}

=head2 has_language($language)

Check if a language is supported.  Takes as argument the language
abbreviation defined in C<share/i18n.json>.

=cut

sub has_language {
    my ($language) = @_;
    exists $langdefs->{$language};
}

=head2 langdef($language)

Get definition of a language.  Takes as argument the language abbreviation
defined in C<share/i18n.json>.

=cut

sub langdef {
    my ($language) = @_;

    return unless has_language($language);
    return $langdefs->{$language};
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

Languages are defined in a JSON-based hash in the __DATA__ section of
L<Test::BDD::Cucumber::I18N::Data>, and have been lifted from the
Gherkin distribution.

=head1 AUTHOR

Gregor Goldbach C<glauschwuffel@nomaden.org>
(based on the works of Pablo Duboue)

=head1 LICENSE

  Copyright 2019-2020, Erik Huelsmann
  Copyright 2014-2019, Gregor Goldbach; Licensed under the same terms as Perl

=cut

1;
