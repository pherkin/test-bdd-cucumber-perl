package Test::BDD::Cucumber::Loader;

=head1 NAME

Test::BDD::Cucumber::Loader - Simplify loading of Step Definition and feature files

=head1 DESCRIPTION

Makes loading Step Definition files and Feature files a breeze...

=head1 METHODS

=head2 load

Accepts a path, and returns a L<Test::BDD::Cucumber::Executor> object with the Step
Definition files loaded, and a list of L<Test::BDD::Cucumber::Model::Feature> objects.

=head2 load_steps

Accepts an L<Test::BDD::Cucumber::Executor> object and a string representing either a
step file, or a directory containing zero or more C<*_steps.pl> files, and loads
the steps in to the executor; if you've used C<load> we'll have already scanned
the feature directory for C<*_steps.pl> files.

=cut

use strict;
use warnings;

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
        $file = file($path);
        $dir  = $file->dir;
    } else {
        $dir = dir($path);
    }

    # Load up the steps
    $class->load_steps( $executor, $dir );

    # Grab the feature files
    my @features = map {
        my $file = file($_);
        my $feature =
          Test::BDD::Cucumber::Parser->parse_file( $file );
      } (
        $file
        ? ( $file . '' )
        : File::Find::Rule->file()->name('*.feature')->in($dir)
      );

    return ( $executor, @features );
}

sub load_steps {
    my ( $class, $executor, $path ) = @_;

    if ( -f $path ) {
        $executor->add_steps( Test::BDD::Cucumber::StepFile->load($path) );
    } else {
        $executor->add_steps( Test::BDD::Cucumber::StepFile->load($_) )
          for File::Find::Rule->file()->name('*_steps.pl')->in($path);
    }

    return $class;
}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2020, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
