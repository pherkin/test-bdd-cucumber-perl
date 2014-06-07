package App::pherkin;

use strict;
use warnings;

use FindBin::libs;
use Getopt::Long;
use Module::Runtime qw(use_module);
use List::Util qw(max);

use Test::BDD::Cucumber::I18n qw(languages langdef readable_keywords keyword_to_subname);
use Test::BDD::Cucumber::Loader;

use Moose;
has 'tags' => ( is => 'rw', isa => 'ArrayRef', required => 0 );
has 'tag_scheme' => ( is => 'rw', isa => 'ArrayRef', required => 0 );

=head1 NAME

App::pherkin - Run Cucumber tests from the command line

=head1 SYNOPSIS

 pherkin
 pherkin some/path/features/

=head1 DESCRIPTION

C<pherkin> will search the directory specified (or C<./features/>) for
feature files (any file matching C<*.feature>) and step definition files (any
file matching C<*_steps.pl>), loading the step definitions and then executing
the features.

Steps that pass will be printed in green, those that fail in red, and those
for which there is no step definition as yellow (for TODO), assuming you're
using the default output harness.

=head1 METHODS

=head2 run

The C<App::pherkin> class, which is what the C<pherkin> command uses, makes
use of the C<run()> method, which accepts currently a single path as a string,
or nothing.

Returns a L<Test::BDD::Cucumber::Model::Result> object for all steps run.

=cut

sub run {
    my ( $self, @arguments ) = @_;

    # localized features will have utf8 in them and options may output utf8 as well
    binmode STDOUT, ':utf8';

    my ($options, @feature_files) = $self->_process_arguments(@arguments);

    my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
        $feature_files[0] || './features/', $self->tag_scheme
    );
    die "No feature files found" unless @features;

    my $harness = $self->_load_harness( $options->{'harness'} );

    my $tag_spec;
    if ($self->tag_scheme) {
        $tag_spec = Test::BDD::Cucumber::Model::TagSpec->new({ tags => $self->tag_scheme });
    }

    $executor->execute( $_, $harness, $tag_spec ) for @features;

    $harness->shutdown();
    return $harness->result;
}

sub _load_harness {
    my ( $self, $harness_module ) = @_;

    unless ( $harness_module =~ m/::/ ) {
        $harness_module = "Test::BDD::Cucumber::Harness::" . $harness_module;
    }

    eval { use_module( $harness_module ) } ||
        die "Unable to load harness [$harness_module]: $@";

    my $harness = $harness_module->new();
    $harness->startup();

    return $harness;
}

sub _process_arguments {
    my ( $self, @args ) = @_;
    local @ARGV = @args;

    # Allow -Ilib, -bl
    Getopt::Long::Configure('bundling');

    my $includes = [];
    my $tags = [];
    GetOptions(
        'I=s@'       => \$includes,
        'l|lib'      => \(my $add_lib),
        'b|blib'     => \(my $add_blib),
        'o|output=s' => \(my $harness),
	't|tags=s@'  => \$tags,
	'i18n=s'     => \(my $i18n)
    );

    if ($i18n) {
        _print_langdef($i18n) unless $i18n eq 'help';
        _print_languages();
    };

    unshift @$includes, 'lib'                   if $add_lib;
    unshift @$includes, 'blib/lib', 'blib/arch' if $add_blib;

    # Munge the output harness
    $harness //= "TermColor";

    lib->import(@$includes) if @$includes;

    # Store our TagSpecScheme
    $self->tag_scheme( $self->_process_tags( @{$tags} ) );

    return ({ harness => $harness }, @ARGV);
}

sub _process_tags {
    my ( $self, @tags ) = @_;

    # This is a bit faffy and possibly suboptimal.
    my $tag_scheme = [];
    my @ands = ();

    # Iterate over our commandline tag strings.
    foreach my $tag (@tags) {
        my @parts = ();

        foreach my $part (split(',', $tag)) {
            # Trim any @ or ~@ from the front of the tag
            $part =~ s/^(~?)@//;

            # ~@tag => "NOT tag" => [ not => tag ]
            if (defined $1 and $1 eq '~') {
                push @parts, [ not => $part ];
            } else {
                push @parts, $part;
            }
        }

        # @tag,@cow => "@tag OR @cow" => [ or => tag, cow ]
        # (It's simpler to always stick an 'or' on the front.)
        push @ands, [ or => @parts ];
    }
    # -t @tag -t @cow => "@tag AND @cow" => [ and => tag, cow ]
    # (It's simpler to always stick an 'and' on the front.)
    $tag_scheme = [ and => @ands ];

    return $tag_scheme;
}

sub _print_languages {

    my @languages=languages();

    my $max_code_length   = max map { length } @languages;
    my $max_name_length   = max map { length(langdef($_)->{name}) } @languages;
    my $max_native_length = max map { length(langdef($_)->{native}) } @languages;

    my $format= "| %-${max_code_length}s | %-${max_name_length}s | %-${max_native_length}s |\n";

    for my $language (sort @languages) {
        my $langdef=langdef($language);
	printf $format, $language, $langdef->{name}, $langdef->{native};
    }
    exit;
}

sub _print_langdef {
    my ($language)=@_;

    my $langdef=langdef($language);

    my @keywords= qw(feature background scenario scenario_outline examples
		     given when then and but);
    my $max_length = max map { length readable_keywords ($langdef->{$_}) } @keywords;

    my $format= "| %-16s | %-${max_length}s |\n";
    for my $keyword (qw(feature background scenario scenario_outline
			examples given when then and but )) {
        printf $format, $keyword, readable_keywords($langdef->{$keyword});
    }

    my $codeformat= "| %-16s | %-${max_length}s |\n";
    for my $keyword (qw(given when then )) {
        printf $codeformat, $keyword.' (code)',
          readable_keywords($langdef->{$keyword}, \&keyword_to_subname);
    }

    exit;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
