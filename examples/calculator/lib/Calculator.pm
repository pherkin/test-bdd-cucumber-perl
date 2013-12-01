package # hide from PAUSE indexer
    Calculator;

use strict;
use warnings;
use Moose;

has 'left'         => ( is => 'rw', isa => 'Num', default => 0 );
has 'right'        => ( is => 'rw', isa => 'Str', default => '' );
has 'operator'     => ( is => 'rw', isa => 'Str', default => '+' );

has 'display'      => ( is => 'rw', isa => 'Str', default => '0' );
has 'equals'       => ( is => 'rw', isa => 'Str', default => ''  );

sub key_in {
    my ( $self, $seq ) = @_;
    my @possible = grep {/\S/} split(//, $seq);
    $self->press($_) for @possible;
}

sub press {
    my ( $self, $key ) = @_;

    # Numbers
    $self->digit( $1 ) if $key =~ m/^([\d\.])$/;

    # Operators
    $self->key_operator( $1 ) if $key =~ m/^([\+\-\/\*])$/;

    # Equals
    $self->equalsign if $key eq '=';

    # Clear
    $self->clear if $key eq 'C';
}

sub clear {
    my $self = shift;
    $self->left(0);
    $self->right('');
    $self->operator('+');
    $self->display('0');
    $self->equals('');
}

sub equalsign {
    my $self = shift;
    $self->key_operator('+');
    my $result = $self->left;
    $self->clear();
    $self->equals( $result );
    $self->display( $result );
}

sub digit {
    my ( $self, $digit ) = @_;

    # Deal with decimal weirdness
    if ( $digit eq '.' ) {
        return if $self->right =~ m/\./;
        $digit = '0.' unless length( $self->right );
    }

    $self->right( $self->right . $digit );
    $self->display( $self->right );
}

sub key_operator {
    my ( $self, $operator ) = @_;

    my $cmd = $self->left . $self->operator .
        ( length($self->right) ? $self->right :
            ( length( $self->equals ) ? $self->equals : '0'));

    $self->right('');
    $self->equals('');

    $self->left( (eval $cmd) + 0 );
    $self->display( $self->left );

    $self->operator( $operator );
}

1;
