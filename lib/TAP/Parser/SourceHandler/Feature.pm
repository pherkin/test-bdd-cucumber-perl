package TAP::Parser::SourceHandler::Feature;

=head1 NAME

TAP::Parser::SourceHandler::Feature - Test::BDD::Cucumber's prove integration

=cut

use strict;
use warnings;

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

    #use Data::Printer; p $source;

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

                # Nasty hack
                if ( length $key > 1 ) {
                    push( @cmd_line, "--$key", $value );
                } else {
                    push( @cmd_line, "-$key", $value );
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

    my ( $input_fh, $output_fh );
    pipe $input_fh, $output_fh;

    # Don't cache the output so prove sees it immediately
    #  (pipes are stdio buffered by default)
    $output_fh->autoflush(1);

    my $dir     = $source->meta->{'file'}->{'dir'};
    my $runtime = $source->{'pherkins'}->{$dir}
        || die "No pherkin instantiation for [$dir]";

    my $executor = $runtime->{'executor'};
    my $pherkin  = $runtime->{'pherkin'};

    my $pid = fork;
    if ($pid) {
        close $output_fh;
        return TAP::Parser::Iterator::PherkinStream->new($input_fh, $pherkin, $pid);
    }

    close $input_fh;
    my $harness = Test::BDD::Cucumber::Harness::TAP->new({ fail_skip => 1 });

    my $context = context();
    # Without the step to set the handles TAP will end up on STDOUT/STDERR
    $context->hub->format->set_handles([$output_fh, $output_fh]);
    $pherkin->harness($harness);
    my $filename = file( $dir . $source->meta->{'file'}->{'basename'} ) . '';

    my $feature = $runtime->{'features'}->{$filename}
        || die "Feature not pre-loaded: [$filename]; have: "
        . ( join '; ', keys %{ $runtime->{'features'} } );

    $pherkin->_run_tests( $executor, $feature );
    $context->release;

    close $output_fh;
    exit;
}

1;
