package Calculator;

use strict;
use warnings;
use Moose;

has 'operator'      => ( is => 'rw', isa => 'Str'   );
has 'display'       => ( is => 'rw', isa => 'Str', default => '0' );
has 'buffer'        => ( is => 'rw', isa => 'Num', default => '0' );
has 'post_operator' => ( is => 'rw', isa => 'Bool'  );

sub press {
    my ( $self, $key ) = @_;
    if ( $key =~ m/([\d\.])/ ) {
        $self->digit( $1 );
    } elsif ( $key =~ m/([\+\-\/\*])/ ) {
        $self->calculate();
        $self->operator( $1 );
        $self->post_operator(1);
    } elsif ( $key eq '=' ) {
        $self->calculate;
    } elsif ( $key eq 'C' ) {
        $self->clear;
    } else {
        die "Unknown key [$key]";
    }
}

sub calculate {
    my ( $self ) = @_;
    return unless $self->operator;
    $self->post_operator(0);
    my $calc = $self->buffer . $self->operator . $self->display;
    warn $calc;
    $self->buffer( eval $calc );
    $self->display( $self->buffer . '' );
    $self->operator('');
}

sub clear {
    my ( $self ) = @_;
    $self->operator('');
    $self->display('0');
    $self->buffer(0);
    $self->post_operator(0);
}

sub digit {
    my ( $self, $digit ) = @_;

    # The next press after an operator should clear the display
    if ( $self->post_operator ) {
        $self->post_operator(0);
        $self->display('0');
    }

    if ( $digit eq '.' ) {
        # Only one period per number
        return if $self->display =~ m/\./;
        # If . is first, display 0.
        if ( $self->display eq '0' ) {
            $self->display('0.');
            return;
        }
    }

    # Over-write if display is currently 0
    $self->display('') if $self->display eq '0';

    # Add digit
    $self->display( $self->display . $digit );
}

1;
