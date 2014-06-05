package Test::BDD::Cucumber::I18n;

=head1 NAME

Test::BDD::Cucumber::I18N - Internationalization

=head1 DESCRIPTION

Internationalization of feature files and step definitions.

=head1 SYNOPSIS

  use Test::BDD::Cucumber::I18N
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

use base 'Exporter';

our @EXPORT_OK =
  qw(languages langdef has_language readable_keywords keyword_to_subname);

use Test::BDD::Cucumber::I18N::Data;

my $langdefs=_initialize_language_definitions_from_shared_json_file();

sub _initialize_language_definitions_from_shared_json_file {
    # Parse keywords hash for all supported languages from the JSON file
    my $langdefs = Test::BDD::Cucumber::I18N::Data::language_definitions();

    # strip asterisks from the keyword definitions since they don't work yet
    for my $language ( keys %$langdefs ) {
        my $langdef = $langdefs->{$language};
        for my $key ( keys %$langdef ) {
            $langdef->{$key} =~ s{\Q*|\E}{};
        }
    }

    return $langdefs;
}

sub languages {
    return keys %$langdefs;
}

sub has_language {
    my ($language) = @_;
    exists $langdefs->{$language};
}

sub langdef {
    my ($language) = @_;

    return unless has_language($language);
    return $langdefs->{$language};
}

sub readable_keywords {
    my ( $string, $transform ) = @_;

    my @keywords = split( /\|/, $string );

    @keywords = map { $transform->($_) } @keywords if $transform;

    return join( ', ', map { '"' . $_ . '"' } @keywords );
}

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

Copyright 2014, Gregor Goldbach; Licensed under the same terms as Perl

=cut

1;
