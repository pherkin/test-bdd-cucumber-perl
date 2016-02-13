package App::pherkin;

use strict;
use warnings;

use lib;
use Getopt::Long;
use Module::Runtime qw(use_module);
use List::Util qw(max);
use Pod::Usage;
use FindBin qw($RealBin $Script);
use YAML::Syck;
use Data::Dumper;
use Path::Class qw/file dir/;

use Test::BDD::Cucumber::I18n
  qw(languages langdef readable_keywords keyword_to_subname);
use Test::BDD::Cucumber::Loader;

use Moose;
has 'step_paths' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'extensions' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'tags'       => ( is => 'rw', isa => 'ArrayRef', required => 0 );
has 'tag_scheme' => ( is => 'rw', isa => 'ArrayRef', required => 0 );

has 'harness' => ( is => 'rw' );

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

    my ($features_path) = $self->_process_arguments(@arguments);
    $features_path ||= './features/';

    my ( $executor, @features ) =
      Test::BDD::Cucumber::Loader->load( $features_path, $self->tag_scheme );
    die "No feature files found in $features_path" unless @features;

    $executor->add_extensions($_) for @{ $self->extensions };

    Test::BDD::Cucumber::Loader->load_steps( $executor, $_ )
      for @{ $self->step_paths };

    return $self->_run_tests( $executor, @features );
}

sub _run_tests {
    my ( $self, $executor, @features ) = @_;

    my $harness = $self->harness;
    $harness->startup();

    my $tag_spec;
    if ( $self->tag_scheme ) {
        $tag_spec = Test::BDD::Cucumber::Model::TagSpec->new(
            { tags => $self->tag_scheme } );
    }

    $_->pre_execute() for @{ $self->extensions };
    $executor->execute( $_, $harness, $tag_spec ) for @features;
    $_->post_execute() for reverse @{ $self->extensions };

    $harness->shutdown();
    return $harness->result;
}

sub _initialize_harness {
    my ( $self, $harness_module ) = @_;

    unless ( $harness_module =~ m/::/ ) {
        $harness_module = "Test::BDD::Cucumber::Harness::" . $harness_module;
    }

    eval { use_module($harness_module) }
      || die "Unable to load harness [$harness_module]: $@";

    $self->harness( $harness_module->new() );
}

sub _find_config_file {
    my ( $self, $config_filename, $debug ) = @_;

    return $config_filename if $config_filename;

    for (
        ( $ENV{'PHERKIN_CONFIG'} || () ),

        # Allow .yaml or .yml for all of the below
        map { ( "$_.yaml", "$_.yml" ) } (

            # Relative locations
            (
                map { file($_) }
                  qw!.pherkin config/pherkin ./.config/pherkin t/.pherkin!
            ),

            # Home locations
            (
                map { dir($_)->file('.pherkin') }
                grep { $_ } map { $ENV{$_} } qw/HOME USERPROFILE/
            )
        )
      )
    {
        return $_ if -f $_;
        print "No config file found in $_\n" if $debug;
    }
    return undef;
}

sub _load_config {
    my ( $self, $profile_name, $proposed_config_filename, $debug ) = @_;

    my $config_filename =
      $self->_find_config_file( $proposed_config_filename, $debug );
    my $config_data_whole;

    # Check we can actually load some data from that file if required
    if ($config_filename) {
        print "Found [$config_filename], reading...\n" if $debug;
        $config_data_whole = LoadFile($config_filename);
    } else {
        if ($profile_name) {
            print "No configuration files found\n" if $debug;
            die
"Profile name [$profile_name] specified, but no configuration file found (use --debug-profiles to debug)";
        } else {
            print "No configuration files found, and no profile specified\n"
              if $debug;
            return;
        }
    }

    $profile_name //= 'default';

    # Check the config file has the right type of data at the profile name
    unless ( ref $config_data_whole eq 'HASH' ) {
        die
"Config file [$config_filename] doesn't return a hashref on parse, instead a ["
          . ref($config_data_whole) . ']';
    }
    my $config_data     = $config_data_whole->{$profile_name};
    my $profile_problem = sub {
        return "Config file [$config_filename] profile [$profile_name]: "
          . shift();
    };
    unless ($config_data) {
        die $profile_problem->("Profile not found");
    }
    unless ( ( my $reftype = ref $config_data ) eq 'HASH' ) {
        die $profile_problem->("[$reftype] but needs to be a HASH");
    }
    print "Using profile [$profile_name]\n" if $debug;

    # Transform it in to an argument list
    my @arguments;
    for my $key ( sort keys %$config_data ) {
        my $value = $config_data->{$key};

        if ( my $reftype = ref $value ) {
            die $profile_problem->(
"Option $key is a [$reftype] but can only be a single value or ARRAY"
            ) unless $reftype eq 'ARRAY';
            push( @arguments, $key, $_ ) for @$value;
        } else {
            push( @arguments, $key, $value );
        }
    }

    if ($debug) {
        print "Arguments to add: " . ( join ' ', @arguments ) . "\n";
    }

    return @arguments;
}

sub _process_arguments {
    my ( $self, @args ) = @_;
    local @ARGV = @args;

    # Allow -Ilib, -bl
    Getopt::Long::Configure( 'bundling', 'pass_through' );

    my %options = (

        # Relating to other configuration options
        config         => ['g|config=s'],
        profile        => ['p|profile=s'],
        debug_profiles => ['debug-profiles'],

        # Standard
        help       => ['h|help|?'],
        includes   => [ 'I=s@', [] ],
        lib        => ['l|lib'],
        blib       => ['b|blib'],
        output     => ['o|output=s'],
        steps      => [ 's|steps=s@', [] ],
        tags       => [ 't|tags=s@', [] ],
        i18n       => ['i18n=s'],
        extensions => [ 'e|extensions=s@', [] ],
    );

    GetOptions(
        map {
            my $x;
            $_->[1] //= \$x;
            ( $_->[0] => $_->[1] );
        } values %options
    );

    my $deref = sub {
        my $key   = shift;
        my $value = $options{$key}->[1];
        return ( ref $value eq 'ARRAY' ) ? $value : $$value;
    };

    pod2usage(
        -verbose => 1,
        -input   => "$RealBin/$Script",
    ) if $deref->('help');

    # Load the configuration file
    my @configuration_options = $self->_load_config( map { $deref->($_) }
          qw/profile config debug_profiles/ );

    # Merge those configuration items
    # First we need a list of matching keys
    my %keys = map {
        my ( $key_basis, $ref ) = @$_;
        map { $_ => $ref } map { s/=.+//; $_ } split( /\|/, $key_basis );
    } values %options;

    # Now let's go through each option. For arrays, we want the configuration
    # options to appear in order at the front. So if configuration had 1, 2,
    # and command line options were 3, 4, we want: 1, 2, 3, 4. This is not
    # straight forward.
    my %additions;
    while (@configuration_options) {
        my ($key)   = shift(@configuration_options);
        my ($value) = shift(@configuration_options);
        my $target = $keys{$key} || die "Unknown configuration option [$key]";

        if ( ref $target ne 'ARRAY' ) {

            # Only use it if we don't have something already
            if ( defined $$target ) {
                print
"Ignoring $key from config file because set on cmd line as $$target\n"
                  if $deref->('debug_profiles');
            } else {
                $$target = $value;
                print "Set $key to $target from config file\n"
                  if $deref->('debug_profiles');
            }

        } else {
            my $array = $additions{ 0 + $target } ||= [];
            push( @$array, $value );
            print "Adding $value near the front of $key\n"
              if $deref->('debug_profiles');
        }
    }
    for my $target ( values %options ) {
        next unless ref $target->[1] eq 'ARRAY';
        my $key = $target->[1] + 0;
        unshift( @{ $target->[1] }, @{ $additions{$key} || [] } );
    }

    if ( $deref->('debug_profiles') ) {
        print "Values are:\n";
        for ( sort keys %options ) {
            printf( " %16s: ", $_ );
            my $value = $deref->($_);
            if ( ref $value ) {
                print join ', ', @$value;
            } else {
                print $value // '[undefined]';
            }
            print "\n";
        }
        exit;
    }

    if ( my $i18n = $deref->('i18n') ) {
        _print_langdef($i18n) unless $i18n eq 'help';
        _print_languages();
    }

    unshift @{ $deref->('includes') }, 'lib' if $deref->('lib');
    unshift @{ $deref->('includes') }, 'blib/lib', 'blib/arch'
      if $deref->('blib');

    # We may need some of the imported paths...
    lib->import( @{ $deref->('includes') } );

    # Load any extensions
    for my $e ( @{ $deref->('extensions') } ) {
        my $e_args = "()";
        $e_args = $1 if $e =~ s/\((.+)\)$//;
        my @e_args = eval $e_args;
        die "Bad arguments in [$e]: $@" if $@;
        use_module $e;
        push( @{ $self->extensions }, $e->new(@e_args) );
    }

    # Munge the output harness
    $self->_initialize_harness( $deref->('output') || "TermColor" );

    # Store any extra step paths
    $self->step_paths( $deref->('steps') );

    # Store our TagSpecScheme
    $self->tag_scheme( $self->_process_tags( @{ $deref->('tags') } ) );

    return ( pop @ARGV );
}

sub _process_tags {
    my ( $self, @tags ) = @_;

    # This is a bit faffy and possibly suboptimal.
    my $tag_scheme = [];
    my @ands       = ();

    # Iterate over our commandline tag strings.
    foreach my $tag (@tags) {
        my @parts = ();

        foreach my $part ( split( ',', $tag ) ) {

            # Trim any @ or ~@ from the front of the tag
            $part =~ s/^(~?)@//;

            # ~@tag => "NOT tag" => [ not => tag ]
            if ( defined $1 and $1 eq '~' ) {
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

    my @languages = languages();

    my $max_code_length = max map { length } @languages;
    my $max_name_length =
      max map { length( langdef($_)->{name} ) } @languages;
    my $max_native_length =
      max map { length( langdef($_)->{native} ) } @languages;

    my $format =
"| %-${max_code_length}s | %-${max_name_length}s | %-${max_native_length}s |\n";

    for my $language ( sort @languages ) {
        my $langdef = langdef($language);
        printf $format, $language, $langdef->{name}, $langdef->{native};
    }
    exit;
}

sub _print_langdef {
    my ($language) = @_;

    my $langdef = langdef($language);

    my @keywords = qw(feature background scenario scenario_outline examples
      given when then and but);
    my $max_length =
      max map { length readable_keywords( $langdef->{$_} ) } @keywords;

    my $format = "| %-16s | %-${max_length}s |\n";
    for my $keyword (
        qw(feature background scenario scenario_outline
        examples given when then and but )
      )
    {
        printf $format, $keyword, readable_keywords( $langdef->{$keyword} );
    }

    my $codeformat = "| %-16s | %-${max_length}s |\n";
    for my $keyword (qw(given when then )) {
        printf $codeformat, $keyword . ' (code)',
          readable_keywords( $langdef->{$keyword}, \&keyword_to_subname );
    }

    exit;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
