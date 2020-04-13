package TAP::Parser::Iterator::PherkinStream;

=head1 NAME

TAP::Parser::Iterator::PherkinStream - Stream with TAP from async BDD process

=cut

use strict;
use warnings;

use base 'TAP::Parser::Iterator::Stream';


sub _initialize {
    my ($self, $fh, $pherkin, $child_pid) = @_;

    $self->{pherkin} = $pherkin;
    $self->{child_pid} = $child_pid;
    return $self->SUPER::_initialize($fh);
}

sub _finish {
    my $self = shift;

    $self->{pherkin}->_post_run();
    if ($self->{child_pid}) {
        waitpid $self->{child_pid}, 0; # reap child process
    }
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

