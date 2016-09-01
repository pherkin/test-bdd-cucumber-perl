package TAP::Parser::SourceHandler::Feature;

use strict;
use warnings;

use Path::Class qw/file/;

use base 'TAP::Parser::SourceHandler';
use TAP::Parser::Iterator::Process;

use App::pherkin;

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

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
            my ( $executor, @features ) = $pherkin->_pre_run($dir);

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

    my $tagspec = $source->config_for($class)->{'tagspec'};

    my ( $input_fh, $output_fh );
    pipe $input_fh, $output_fh;

    my $tb = Test::Builder->create();
    $tb->output($output_fh);

    my $it = TAP::Parser::Iterator::Stream->new($input_fh);

    my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
        {   fail_skip    => 1,
            _tb_instance => $tb,
        }
    );

    my $dir     = $source->meta->{'file'}->{'dir'};
    my $runtime = $source->{'pherkins'}->{$dir}
        || die "No pherkin instantiation for [$dir]";

    my $executor = $runtime->{'executor'};
    my $pherkin  = $runtime->{'pherkin'};
    $pherkin->harness($harness);

    my $filename = file( $dir . $source->meta->{'file'}->{'basename'} ) . '';

    my $feature = $runtime->{'features'}->{$filename}
        || die "Feature not pre-loaded: [$filename]; have: "
        . ( join '; ', keys %{ $runtime->{'features'} } );

    $pherkin->_run_tests( $executor, $feature );

    return $it;
}

1;
