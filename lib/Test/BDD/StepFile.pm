package Test::BDD::StepFile;

use strict;
use warnings;
use File::Find;
use Ouch;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Given Then);

our @definitions;

sub Given { push( @definitions, [ Given => @_ ] ) }
sub When  { push( @definitions, [ When  => @_ ] ) }
sub Then  { push( @definitions, [ Then  => @_ ] ) }

#sub Step  { push( @definitions, [ Step  => @_ ] ) }

sub load {
    my ( $class, $filename ) = @_;

    {
        local @definitions;
        do $filename;
        ouch 'step_compilation', "Step file [$filename] failed to load: $@"
            if $@;
        return @definitions;
    }

}

1;