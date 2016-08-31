package TAP::Parser::SourceHandler::Feature;

use strict;
use warnings;

use base 'TAP::Parser::SourceHandler';
use TAP::Parser::Iterator::Process;

use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

use Path::Class qw/file/;

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub can_handle {
    my ( $class, $source ) = @_;

    #use Data::Printer; p $source; exit;

    if (   $source->meta->{'is_file'}
        && $source->meta->{'file'}->{'basename'} =~ m/\.feature$/ )
    {

        my $dir = $source->meta->{'file'}->{'dir'};
        unless ( $source->{'cucumber_executors'}->{$dir} ) {
            my ($executor) = Test::BDD::Cucumber::Loader->load($dir);
            $source->{'cucumber_executors'}->{$dir} = $executor;
        }
        return 1;
    }

    return 0;
}

sub make_iterator {
    my ( $class, $source ) = @_;

    my $tagspec = $source->config_for($class)->{'tagspec'};

    my ($input_fh, $output_fh);
    pipe $input_fh, $output_fh;

    #open( my $output_fh, '>', 'filename.tmp');
    my $tb = Test::Builder->create();
    $tb->output($output_fh);

    #open( my $input_fh, '<', 'filename.tmp');

    my $it = TAP::Parser::Iterator::Stream->new($input_fh);

    my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
        {   fail_skip    => 1,
            _tb_instance => $tb,
        }
    );

    my $dir      = $source->meta->{'file'}->{'dir'};
    my $executor = $source->{'cucumber_executors'}->{$dir}
        || die "No executor instantiated for [$dir]";

    my $feature = Test::BDD::Cucumber::Parser->parse_file(
        $dir . $source->meta->{'file'}->{'basename'}, $tagspec );

    $executor->execute( $feature, $harness );
    $tb->done_testing();

    return $it;
}

1;
