package Test::BDD::Cucumber::StepFile;

=head1 NAME

Test::BDD::Cucumber::StepFile - Functions for creating and loading Step Definitions

=cut

use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use File::Spec qw/rel2abs/;
use Scalar::Util qw/reftype/;

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
 # or: use strict; use warnings; use Test2::V0;

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

sub _ensure_meta {
    my ($p, $f, $l) = caller(1);
    if (ref $_[1] and reftype $_[1] eq 'HASH') {
        $_[1]->{source} = $f;
        $_[1]->{line} = $l;
        return @_;
    }
    else {
        return ($_[0], { source => $f, line => $l }, $_[1]);
    }
}

# Mapped to Given, When, and Then as part of the i18n mapping below
sub _Given { push( @definitions, [ Given => _ensure_meta(@_) ] ) }
sub _When  { push( @definitions, [ When  => _ensure_meta(@_) ] ) }
sub _Then  { push( @definitions, [ Then  => _ensure_meta(@_) ] ) }

sub Step { push( @definitions, [ Step => _ensure_meta(@_) ] ) }

sub Transform { push( @definitions, [ Transform => _ensure_meta(@_) ] ) }
sub Before    { push( @definitions, [ Before    => _ensure_meta(qr//, @_) ] ) }
sub After     { push( @definitions, [ After     => _ensure_meta(qr//, @_) ] ) }

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
        next unless length $subname;

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

# We need an extra level of indirection when we want to support step functions
# loaded into their own packages (which we do, for cleanliness); the exporter
# binds the subs declared below to S and C symbols in the imported-into package
# That prevents us from binding a different function to these symbols at
# execution time.
# We *can* bind the _S and _C functions declared below.
sub S { _S() }
sub C { _C() }

sub _S { croak "You can only call `S` inside a step definition" }
sub _C { croak "You can only call `C` inside a step definition" }

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

        # Debian Jessie with security patches requires an absolute path
        do File::Spec->rel2abs($filename);
        die "Step file [$filename] failed to load: $@" if $@;
        return @definitions;
    }

}

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

  Copyright 2019-2020, Erik Huelsmann
  Copyright 2011-2019, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
