package Test::BDD::Executor;

use strict;
use warnings;
use FindBin::libs;

use Test::More;

sub new {
    my $class = shift();
    bless {
        executor_stash => {},
        steps          => []
    }, $class;
}

sub add_steps {
	my ( $self, @steps ) = @_;
	push( @{ $self->{'steps'} }, @steps );
}

sub execute {
    my ( $self, $data ) = @_;

    for my $section ( $data->{'background'}, @{ $data->{'scenarios'} } ) {

        note "Executing: " . $section->{'name'};

        for my $cmd ( @{$section->{'lines'}} ) {
            my ( $verb, $text ) = @$cmd;
            $self->dispatch( $verb, $text, {} );
        }

    }
}

sub dispatch {
    my ( $self, $verb, $text, $dataset ) = @_;
    my $matched;

    for my $cmd ( @{ $self->{'steps'}->{$verb} || [] } ) {
        my ( $regular_expression, $coderef ) = @$cmd;

        if ( my @matches = $text =~ $regular_expression ) {
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
