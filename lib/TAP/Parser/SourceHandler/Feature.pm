use v5.14;
use warnings;

package TAP::Parser::SourceHandler::Feature;

=head1 NAME

TAP::Parser::SourceHandler::Feature - Test::BDD::Cucumber's prove integration

=cut


use Path::Class qw/file/;
use Test2::API qw/context/;

use base 'TAP::Parser::SourceHandler';

use TAP::Parser::Iterator::PherkinStream;

use App::pherkin;

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TAP;

use Path::Class qw/file/;

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub can_handle {
    my ( $class, $source ) = @_;

    if (   $source->meta->{'is_file'}
        && $source->meta->{'file'}->{'basename'} =~ m/\.feature$/ )
    {

        my $dir = $source->meta->{'file'}->{'dir'};
        unless ( $source->{'pherkins'}->{$dir} ) {

            my $pherkin = App::pherkin->new();

            # Reformulate before passing to the cmd line parser
            my @cmd_line;
            my %options = %{ $source->config_for($class) };
            while ( my ( $key, $value ) = each %options ) {

                # --feature-option 'tags=@something'
                # --feature-option 'tags=@somethingelse'
                #
                # is passed in %options as:
                # { ..., tags => [ '@something', '@somethingelse' ], ... }
                #
                # Now unfold that back into an argument array as
                #  --tags @something --tags @somethingelse
                $value = [ $value ] unless ref $value;
                for my $v (@$value) {
                    # Nasty hack
                    if ( length $key > 1 ) {
                        push( @cmd_line, "--$key", $v );
                    } else {
                        push( @cmd_line, "-$key", $v );
                    }
                }
            }

            my ( $executor, @features )
                = $pherkin->_pre_run( @cmd_line, $dir );

            $source->{'pherkins'}->{$dir} = {
                pherkin  => $pherkin,
                executor => $executor,
                features => {
                    map { ( file( $_->document->filename ) . '' ) => $_ }
                        @features
                }
            };
        }
        return 1;
    }

    return 0;
}

sub make_iterator {
    my ( $class, $source ) = @_;

    my ( $input_out_fh, $output_out_fh );
    pipe $input_out_fh, $output_out_fh;
    binmode $output_out_fh, ':utf8';

    my ( $input_err_fh, $output_err_fh );
    pipe $input_err_fh, $output_err_fh;
    binmode $output_err_fh, ':utf8';

    # Don't cache the output so prove sees it immediately
    #  (pipes are stdio buffered by default)
    $output_out_fh->autoflush(1);
    $output_err_fh->autoflush(1);

    my $dir     = $source->meta->{'file'}->{'dir'};
    my $runtime = $source->{'pherkins'}->{$dir}
        || die "No pherkin instantiation for [$dir]";

    my $executor = $runtime->{'executor'};
    my $pherkin  = $runtime->{'pherkin'};

    my $pid = fork;
    if ($pid) {
        close $output_out_fh;
        close $output_err_fh;
        return TAP::Parser::Iterator::PherkinStream
            ->new($input_out_fh, $input_err_fh, $pherkin, $pid);
    }

    # prevent uncaught exceptions to return up the call stack
    #  causing essentially two prove instances to run.
    eval {
        close $input_out_fh;
        close $input_err_fh;
        my $harness =
            Test::BDD::Cucumber::Harness::TAP->new({ fail_skip => 1 });

        my $context = context();
        # Without the step to set the handles TAP will end up on STDOUT/STDERR
        $context->hub->format->set_handles([$output_out_fh, $output_err_fh]);
        $context->release;
        $pherkin->harness($harness);
        my $filename =
            file( $dir . $source->meta->{'file'}->{'basename'} ) . '';

        my $feature = $runtime->{'features'}->{$filename}
        || die "Feature not pre-loaded: [$filename]; have: "
            . ( join '; ', keys %{ $runtime->{'features'} } );

        my $exit_code = $pherkin->_run_tests( $executor, $feature );

        close $output_out_fh;
        close $output_err_fh;
        $pherkin->_post_run;

        exit $exit_code;
    };
    exit 255;
}

1;
