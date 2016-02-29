#!perl

use strict;
use warnings;
use lib 't/lib';

use Cwd;
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
    [   'top_level_array.yaml',
        default => qr/hashref on parse, instead a \[ARRAY\]/
    ],
    [ 'readable.yaml', arrayref   => qr/\[ARRAY\] but needs to be a HASH/ ],
    [ 'readable.yaml', hashoption => qr/Option foo is a \[HASH\]/ ],
    [ 'readable.yaml', missing    => qr/Profile not found/ ],

    # YAML::Syck segaults on this for older Perls ¯\_(ツ)_/¯
    (     ( $] > 5.008008 )
        ? ( [ 'not_yaml.yaml', default => qr/syntax error/ ] )
        : ()
    ),
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
    '-p'          => 'ehuelsmann',
    '--steps'     => '3',
    '--steps'     => '4',
    '-o'          => 'Data',
    '-e'          => 'Test::CucumberExtensionPush({ id => 2, hash => {}})',
    '--extension' => 'Test::CucumberExtensionPush({ id => 3, hash => {}})',
);

isa_ok( $p->harness, 'Test::BDD::Cucumber::Harness::Data', 'Harness set' );
is_deeply( $p->{'step_paths'},
           [  # extension loaded 3 times
             dir(getcwd)->subdir(qw( t lib Test extension_steps )),
             dir(getcwd)->subdir(qw( t lib Test extension_steps )),
             dir(getcwd)->subdir(qw( t lib Test extension_steps )),
             1, 2, 3, 4 ],
           'Step paths set' );

is( $p->extensions->[0]->id, 1, "Cmdline extension 1" );
is( $p->extensions->[1]->id, 2, "Cmdline extension 2" );
is( $p->extensions->[2]->id, 3, "Config extension 3" );

done_testing();
