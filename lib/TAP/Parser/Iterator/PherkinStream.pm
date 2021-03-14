package TAP::Parser::Iterator::PherkinStream;

=head1 NAME

TAP::Parser::Iterator::PherkinStream - Stream with TAP from async BDD process

=cut

use strict;
use warnings;

use base 'TAP::Parser::Iterator';

use IO::Select;

sub _initialize {
    my ($self, $out_fh, $err_fh, $pherkin, $child_pid) = @_;

    $self->{pherkin}   = $pherkin;
    $self->{child_pid} = $child_pid;
    $self->{sel}       = IO::Select->new($out_fh, $err_fh);
    $self->{out_fh}    = $out_fh;
    $self->{err_fh}    = $err_fh;

    return $self;
}

sub _finish {
    my $self = shift;

    $self->{pherkin}->_post_run();
    if ($self->{child_pid}) {
        waitpid $self->{child_pid}, 0; # reap child process
        $self->{wait} = $?;
        $self->{exit} = $? >> 8;
    }

    return $self;
}

sub wait { shift->{wait} }
sub exit { shift->{exit} }

sub _next {
    my $self = shift;

    my @buf = ();
    my $part = '';
    return sub {
        return shift @buf if @buf;

        while (my @ready = $self->{sel}->can_read) {
            for my $fh (@ready) {
                my $stderr = '';

              READ:
                {
                    my $got = sysread $fh, my ($chunk), 2048;
                    if ($got == 0) {
                        $self->{sel}->remove($fh);
                    }
                    elsif ($fh == $self->{err_fh}) {
                        $stderr .= $chunk;
                        my @lines = split(/\n/, $stderr, -1);
                        $stderr = pop @lines;

                        for my $line (@lines) {
                            utf8::decode($line);
                            print STDERR $line . "\n";
                        }
                        goto READ if $got == 2048;

                        utf8::decode($stderr)
                            or die 'Subprocess provided non-utf8 data';
                        print STDERR $stderr . "\n";
                    }
                    else {
                        $part .= $chunk;
                        push @buf, split(/\n/, $part, -1);
                        $part = pop @buf;

                        my $rv = shift @buf;
                        if (defined $rv) {
                            utf8::decode($rv)
                                or die 'Subprocess provided non-utf8 data';
                            return $rv;
                        }
                    }
                }
            }
        }

        if ($part) {
            $part = '';
            return $part;
        }

        $self->_finish;
        return;
    };
}

sub next_raw {
    my $self = shift;
    $self->{_next} ||= $self->_next;
    return $self->{_next}->();
}

sub get_select_handles {
    my $self = shift;

    # return our handle in case it's a socket or pipe (select()-able)
    return ( $self->{fh}, $self->{err_fh});
}



1;

