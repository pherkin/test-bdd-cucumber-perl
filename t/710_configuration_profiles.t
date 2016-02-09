#!perl

use strict;
use warnings;

use Path::Class qw/dir/;

use Test::More;
use App::pherkin;
use Test::Exception;

my $class = "App::pherkin";

# Check _find_config_file

is( $class->_find_config_file('foobar'),
    'foobar', "_find_config_file passes filename through" );
{
    local $ENV{'PHERKIN_CONFIG'} = $0;
    is( $class->_find_config_file(),
        $0, "_find_config_file checks \$ENV{'PHERKIN_CONFIG'}" );
}

# Various poorly-formed files or configs
my $dir = dir('t/pherkin_config_files');

for (
    [ 'not_yaml.yaml', default => qr/syntax error/ ],
    [
        'top_level_array.yaml',
        default => qr/hashref on parse, instead a \[ARRAY\]/
    ],
    [ 'readable.yaml', arrayref   => qr/\[ARRAY\] but needs to be a HASH/ ],
    [ 'readable.yaml', hashoption => qr/Option foo is a \[HASH\]/ ],
    [ 'readable.yaml', missing    => qr/Profile not found/ ],
  )
{
    my ( $filename, $profile_name, $expecting ) = @$_;

    throws_ok { $class->_load_config( $profile_name, $dir->file($filename) ) }
    $expecting, "Loading $filename / $profile_name caught";
}

# We can read a known-good config
is_deeply(
    [ $class->_load_config( readable => $dir->file('readable.yaml') ) ],
    [ f => 1, f => 2 ],
    "readable/readable read OK"
);
is_deeply(
    [ $class->_load_config( undef, $dir->file('readable.yaml') ) ],
    [ bar => 'baz', foo => 'bar' ],
    "readable/[default] read OK"
);

# Empty pass-through
is_deeply( [ $class->_load_config( undef, undef ) ],
    [], "Empty configuration passed through" );

my $p = App::pherkin->new();
$p->_process_arguments(
    '-g',
    $dir->file('readable.yaml'),
    '-p' => 'ehuelsmann',
    '--steps' => '3',
    '-o' => 'Data',
);

isa_ok( $p->harness, 'Test::BDD::Cucumber::Harness::Data', 'Harness set' );
is_deeply(
    $p->{'step_paths'},
    [ "/usr/share/perl/5.14.2/Test/BDD/Plugin/steps", "~/your-project/steps", 3 ],
    'Step paths set'
);

done_testing();
