package Test::BDD::Loader;

use strict;
use warnings;

use Ouch;
use Path::Class;
use File::Find::Rule;

use Test::BDD::Executor;
use Test::BDD::Parser;
use Test::BDD::StepFile();

sub load {
    my ( $class, $path ) = @_;
    my $executor = Test::BDD::Executor->new();

    # Either load a feature or a directory...
    my ( $dir, $file );
    if ( -f $path ) {
        $file = file( $path );
        $dir  = $file->dir;
    } else {
        $dir = dir( $path );
    }

    # Load up the steps
    $executor->add_steps(
        Test::BDD::StepFile->load( $_ )
    ) for File::Find::Rule
        ->file()
        ->name( '*_steps.pl' )
        ->in( $dir );

    # Grab the feature files
    my @features = map {
        my $file = $_;
        my $feature = eval { Test::BDD::Parser->parse_file( $file ) };
        unless ( $feature ) {
            my $failure = (
                # Was there an error?
                $@ ? (
                    # Was it returned by Ouch?
                    ref( $@ ) ? (
                        $@->code . ': ' .
                        $@->message . ': ' .
                        $@->data->debug_summary
                    # Error not returned by Ouch
                    ) : "Unhandled error: $@"
                # No error found!
                ) : "Unknown error"
            );
            ouch 'failed_feature_load', "Unable to load $file: $failure";
        }
    } ( $file ? ($file) : File::Find::Rule
        ->file()
        ->name( '*.feature' )
        ->in( $dir ) );

    return ( $executor, @features );
}

1;
