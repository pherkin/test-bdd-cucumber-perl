package Test::BDD::Cucumber::Loader;

=head1 NAME

Test::BDD::Cucumber::Loader - Simplify loading of Step Definition and feature
files

=head1 DESCRIPTION

Makes loading Step Definition files and Feature files a breeze...

=head1 METHODS

=head2 load

Accepts a path, and returns a L<Test::BDD::Executor> object with the Step
Definition files loaded, and a list of L<Test::BDD::Model::Feature> objects.

=cut

use strict;
use warnings;

use Ouch;
use Path::Class;
use File::Find::Rule;

use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::StepFile();

sub load {
    my ( $class, $path ) = @_;
    my $executor = Test::BDD::Cucumber::Executor->new();

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
        Test::BDD::Cucumber::StepFile->load( $_ )
    ) for File::Find::Rule
        ->file()
        ->name( '*_steps.pl' )
        ->in( $dir );

    # Grab the feature files
    my @features = map {
        my $file = $_;
        my $feature = eval { Test::BDD::Cucumber::Parser->parse_file( $file ) };
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

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
