package Test::BDD::Cucumber::StepFile;

=head1 NAME

Test::BDD::Cucumber::StepFile - Functions for creating and loading Step Definitions

=cut

use strict;
use warnings;
use Carp qw/croak/;

use Test::BDD::Cucumber::I18n qw(languages langdef keyword_to_subname);
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(Step Transform Before After C S);

our @definitions;

=head1 DESCRIPTION

Provides the Given/When/Then functions, and a method for loading Step Definition
files and returning the steps.

=head1 SYNOPSIS

Defining steps:

 #!perl

 use strict; use warnings; use Test::More;

 use Test::BDD::Cucumber::StepFile;

 Given     'something',          sub { print "YEAH!" }
 When      qr/smooooth (\d+)/,   sub { print "YEEEHAH $1" }
 Then      qr/something (else)/, sub { S->{'match'} = $1 }
 Step      qr/die now/,          sub { die "now" }
 Transform qr/^(\d+)$/,          sub { int $1 }
 Before                          sub { setup_db() }
 After                           sub { teardown() }

Loading steps, in a different file:

 use Test::BDD::Cucumber::StepFile;
 my @steps = Test::BDD::Cucumber::StepFile->load('filename_steps.pl');

=head1 EXPORTED FUNCTIONS

=head2 Given

=head2 When

=head2 Then

=head2 Step

=head2 Transform

=head2 Before

=head2 After

Accept a regular expression or string, and a coderef. Some cute tricks ensure
that when you call the C<load()> method on a file with these statements in,
these are returned to it...

=cut

# Mapped to Given, When, and Then as part of the i18n mapping below
sub _Given { push( @definitions, [ Given => @_ ] ) }
sub _When  { push( @definitions, [ When  => @_ ] ) }
sub _Then  { push( @definitions, [ Then  => @_ ] ) }

sub Step { push( @definitions, [ Step => @_ ] ) }

sub Transform { push( @definitions, [ Transform => @_ ] ) }
sub Before    { push( @definitions, [ Before    => @_ ] ) }
sub After     { push( @definitions, [ After     => @_ ] ) }

my @SUBS;

for my $language ( languages() ) {
    my $langdef = langdef($language);

    _alias_function( $langdef->{given}, \&_Given );
    _alias_function( $langdef->{when},  \&_When );
    _alias_function( $langdef->{then},  \&_Then );

    # Hm ... in cucumber, all step defining keywords are the same.
    # Here, the parser replaces 'and' and 'but' with the last verb. Tricky ...
    #    _alias_function( $langdef->{and}, \&And);
    #    _alias_function( $langdef->{but}, \&But);
}

push @EXPORT, @SUBS;

sub _alias_function {
    my ( $keywords, $f ) = @_;

    my @keywords = split( '\|', $keywords );
    for my $word (@keywords) {

        # asterisks won't be aliased to any sub
        next if $word eq '*';

        my $subname = keyword_to_subname($word);

        {
            no strict 'refs';
            no warnings 'redefine';
            no warnings 'once';

            *$subname = $f;
            push @SUBS, $subname;
        }
    }
}

=head2 C

=head2 S

Return the context and the Scenario stash, respectively, B<but only when called
inside a step definition>.

=cut

sub S { croak "You can only call `S` inside a step definition" }
sub C { croak "You can only call `C` inside a step definition" }

=head2 load

Loads a file containing step definitions, and returns a list of the steps
defined in it, of the form:

 (
  [ 'Given', qr/abc/, sub { etc } ],
  [ 'Step',  'asdf',  sub { etc } ]
 )

=cut

sub load {
    my ( $class, $filename ) = @_;
    {
        local @definitions;
        do $filename;
        die "Step file [$filename] failed to load: $@" if $@;
        return @definitions;
    }

}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2014, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
