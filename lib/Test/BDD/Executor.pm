package Test::BDD::Executor;

use strict;
use warnings;
use FindBin::libs;

use Test::More;

my %tasks = (
    given => [
        ["Select user permissions", qr/^you are a (.+) user$/i, 1 => sub {
            my ( $self, $matches ) = @_;
            $self->{'stash'}->{'user_perms'} = $auths{ lc( $matches->[0] ) }
                || die "Unknown user type";
        }],
    ]
);

sub new {
	my $class = shift();
	bless { stash => {} }, $class;
}

sub execute {
	my ( $self, $data ) = @_;

    for my $section ( $data->{'background'}, @{ $data->{'scenarios'} } ) {
        my @datasets = @{ $section->{'examples'} || [] };
        push( @datasets, {} ) unless @datasets;
        for my $dataset ( @datasets ) {
            note "Executing: " . $section->{'name'};
            if ( @datasets > 1 ) {
                note "Using dataset: " . pp( $dataset );
            }

            for my $cmd ( @{$section->{'lines'}} ) {
                my ( $verb, $text ) = @$cmd;
                $self->dispatch( $verb, $text, $dataset );
            }
        }
    }
}

sub dispatch {
    my ( $self, $verb, $text, $dataset ) = @_;
    my $matched;

    # Flesh out the text with the dataset

    for my $cmd ( @{ $tasks{ $verb } || [] } ) {
        my $re = $cmd->[1];
        if ( my @matches = $text =~ $re ) {
            $matched++;
            note "Matched $cmd->[0]";
            $cmd->[3]->( $self, \@matches );
            last if $cmd->[2];
        }
    }

    warn "Can't find a match for [$verb]: $text" unless $matched;
}

sub setup {
    my $self = shift;

    return;
}

1;
