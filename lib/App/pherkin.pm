package App::pherkin;

use strict;
use warnings;
use FindBin::libs;
use Getopt::Long;
use Data::Dumper;

use Moose;
has 'tags' => ( is => 'rw', isa => 'ArrayRef', required => 0 );
has 'tag_scheme' => ( is => 'rw', isa => 'ArrayRef', required => 0 );

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
for which there is no step definition as yellow (for TODO).

=cut

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TermColor;

=head1 METHODS

=head2 run

The C<App::pherkin> class, which is what the C<pherkin> command uses, makes
use of the C<run()> method, which accepts currently a single path as a string,
or nothing.

Returns a L<Test::BDD::Cucumber::Model::Result> object for all steps run.

=cut

sub run {
    my ( $self, @arguments ) = @_;

    @arguments = $self->_process_arguments(@arguments);

    my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
        $arguments[0] || './features/', $self->tag_scheme
    );
    die "No feature files found" unless @features;

    my $harness  = Test::BDD::Cucumber::Harness::TermColor->new();
    my $tag_spec;
    if ($self->tag_scheme) {
        $tag_spec = Test::BDD::Cucumber::Model::TagSpec->new({ tags => $self->tag_scheme });
    }
    $executor->execute( $_, $harness, $tag_spec ) for @features;

    return $harness->result;
}

sub _process_arguments {
    my ( $self, @args ) = @_;
    local @ARGV = @args;

    # Allow -Ilib, -bl
    Getopt::Long::Configure('bundling');

    my $includes = [];
    my $tags = [];
    GetOptions(
        'I=s@'   => \$includes,
        'l|lib'  => \(my $add_lib),
        'b|blib' => \(my $add_blib),
        't|tags=s@' => \$tags,
    );
    unshift @$includes, 'lib'                   if $add_lib;
    unshift @$includes, 'blib/lib', 'blib/arch' if $add_blib;

    lib->import(@$includes) if @$includes;

    # Store our TagSpecScheme
    $self->tag_scheme( $self->_process_tags( @{$tags} ) );

    return @ARGV;
}

sub _process_tags {
    my ( $self, @tags ) = @_;

    # This is a bit faffy and possibly suboptimal.
    my $tag_scheme = [];
    my @ands = ();

    # Iterate over our commandline tag strings.
    foreach my $tag (@tags) {
        my @parts = ();

        foreach my $part (split(',', $tag)) {
            # Trim any @ or ~@ from the front of the tag
            $part =~ s/^(~?)@//;

            # ~@tag => "NOT tag" => [ not => tag ]
            if (defined $1 and $1 eq '~') {
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


=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut

1;
