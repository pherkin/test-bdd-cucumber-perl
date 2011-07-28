package Test::BDD::StepFile;

use strict;
use warnings;
use File::Find;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Given Then);

our @definitions;

sub Given { push( @definitions, [ Given => @_ ] ) }
sub Then  { push( @definitions, [ Then  => @_ ] ) }

sub all {
    my $class = shift;
    my @copy = @definitions;
    @definitions = ();
    return @copy;
}

sub read_file {
    my ( $class, $filename ) = @_;
    do $filename;
    die $@ if $@;
}

sub read_dir {
    my ( $class, $path ) = @_;
    my @files;
    find(sub {
        m/_steps\.pl$/ && push(@files, $File::Find::name )
    }, $path);
    die "No files found in $path" unless @files;
    $class->read_file( $_ ) for @files;
}

1;