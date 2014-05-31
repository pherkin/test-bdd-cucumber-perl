package Test::BDD::Cucumber::I18n;

=head1 NAME

Test::BDD::Cucumber::I18N - Internationalization

=head1 DESCRIPTION

Internationalization of feature files and step definitions.

=head1 SYNOPSIS

use Test::BDD::Cucumber::I18N qw(languages has_language langdef);

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

use Encode qw(encode);
use JSON::MaybeXS;
use utf8;
use Ouch;
use File::ShareDir qw( dist_dir );
use File::Spec;

use base 'Exporter';

our @EXPORT_OK =
  qw(languages langdef has_language readable_keywords keyword_to_subname);

my $langdefs = _initialize_language_definitions_from_shared_json_file();

sub _initialize_language_definitions_from_shared_json_file {
    my $dir = dist_dir('Test-BDD-Cucumber');
    my $filename = File::Spec->catfile( $dir, 'i18n.json' );
    ouch 'i18n_error', 'I18n file does not exist', $filename
      unless -e $filename;
    my $success = open( my $fh, '<', $filename );
    ouch 'i18n_error', "Unable to open i18n file: $!", $filename
      unless $success;

    # Parse keywords hash for all supported languages from the JSON file
    my $json = join '', (<$fh>);
    my $langdefs = decode_json($json);

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
    return keys $langdefs;
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

Languages are defined in a JSON-based hash in the __DATA__ section of this file.
That hash the i18n.json of the Gherkin project (the parser for
features that the original Cucumber tool uses). Just copy Gherkin's i18n.json
in the data section to update language definitions.

Gherkin can be found at L<https://github.com/cucumber/gherkin>,
its i18n.json at L<https://github.com/cucumber/gherkin/blob/master/lib/gherkin/i18n.json>.

=head1 AUTHOR

Gregor Goldbach C<glauschwuffel@nomaden.org>
(based on the works of Pablo Duboue)

=head1 LICENSE

Copyright 2014, Gregor Goldbach; Licensed under the same terms as Perl

Definition of languages based on data from Gherkin.
Copyright (c) 2009-2013 Mike Sassak, Gregory Hnatiuk, Aslak Hellesøy

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
