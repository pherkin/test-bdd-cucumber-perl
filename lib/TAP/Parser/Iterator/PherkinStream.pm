package TAP::Parser::Iterator::PherkinStream;

use strict;
use warnings;

use base 'TAP::Parser::Iterator::Stream';


sub _initialize {
    my ($self, $fh, $pherkin) = @_;

    $self->{pherkin} = $pherkin;
    return $self->SUPER::_initialize($fh);
}

sub _finish {
    my $self = shift;

    $self->{pherkin}->_post_run();
    return $self->SUPER::_finish(@_);
}

sub get_select_handles {
    my $self = shift;

    # return our handle in case it's a socket or pipe (select()-able)
    return ( $self->{fh}, )
        if (-S $self->{fh} || -p $self->{fh});

    return;
}


1;

