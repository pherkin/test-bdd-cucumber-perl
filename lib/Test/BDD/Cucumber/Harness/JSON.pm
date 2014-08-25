package Test::BDD::Cucumber::Harness::JSON;

=head1 NAME

Test::BDD::Cucumber::Harness::JSON - Generate results to JSON file

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass that generates JSON output file.

So that it is possible use tools like
L<"Publish pretty cucumber reports"|https://github.com/masterthought/cucumber-reporting>.

=cut

use Moose;
use JSON::MaybeXS;
use Time::HiRes qw ( time );

extends 'Test::BDD::Cucumber::Harness::Data';

=head1 CONFIGURABLE ATTRIBUTES

=head2 fh

A filehandle to write output to; defaults to C<STDOUT>

=cut

has 'fh' => ( is => 'rw', isa => 'FileHandle', default => sub { \*STDOUT } );

=head2 json_args

List of options to be passed to L<JSON::MaybeXS>'s C<new()> method

=cut

has json_args => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { utf8 => 1, pretty => 1 } }
);

#

has all_features => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has current_feature  => ( is => 'rw', isa => 'HashRef' );
has current_scenario => ( is => 'rw', isa => 'HashRef' );
has step_start_at    => ( is => 'rw', isa => 'Num' );

sub feature {
    my ( $self, $feature ) = @_;
    $self->current_feature( $self->format_feature($feature) );
    push @{ $self->all_features }, $self->current_feature;
}

sub scenario {
    my ( $self, $scenario, $dataset ) = @_;
    $self->current_scenario( $self->format_scenario($scenario) );
    push @{ $self->current_feature->{elements} }, $self->current_scenario;
}

sub step {
    my ( $self, $context ) = @_;
    $self->step_start_at( time() );
}

sub step_done {
    my ( $self, $context, $result ) = @_;
    my $duration = time() - $self->step_start_at;
    my $step_data = $self->format_step( $context, $result, $duration );
    push @{ $self->current_scenario->{steps} }, $step_data;
}

sub shutdown {
    my ($self) = @_;
    my $json   = JSON::MaybeXS->new( %{ $self->json_args } );
    my $fh     = $self->fh;
    print $fh $json->encode( $self->all_features );
}

##################################
### Internal formating methods ###
##################################

sub get_keyword {
    my ( $self, $line_ref ) = @_;
    my ($keyword) = $line_ref->content =~ /^(\w+)/;
    return $keyword;
}

sub format_tags {
    my ( $self, $tags_ref ) = @_;
    return [ map { { name => '@' . $_ } } @$tags_ref ];
}

sub format_description {
    my ( $self, $feature ) = @_;
    return join "\n", map { $_->content } @{ $feature->satisfaction };
}

sub format_feature {
    my ( $self, $feature ) = @_;
    return {
        uri         => $feature->name_line->filename,
        keyword     => $self->get_keyword( $feature->name_line ),
        id          => "feature-" . int($feature),
        name        => $feature->name,
        line        => $feature->name_line->number,
        description => $self->format_description($feature),
        tags        => $self->format_tags( $feature->tags ),
        elements    => []
    };
}

sub format_scenario {
    my ( $self, $scenario, $dataset ) = @_;
    return {
        keyword => $self->get_keyword( $scenario->line ),
        id      => "scenario-" . int($scenario),
        name    => $scenario->name,
        line    => $scenario->line->number,
        tags    => $self->format_tags( $scenario->tags ),
        type    => $scenario->background ? 'background' : 'scenario',
        steps   => []
    };
}

sub format_step {
    my ( $self, $step_context, $result, $duration ) = @_;
    my $step = $step_context->step;
    return {
        keyword => $step ? $step->verb_original : $step_context->verb,
        name => $step_context->text,
        line => $step ? $step->line->number : 0,
        result => $self->format_result( $result, $duration )
    };
}

my %OUTPUT_STATUS = (
    passing   => 'passed',
    failing   => 'failed',
    pending   => 'pending',
    undefined => 'skipped',
);

sub format_result {
    my ( $self, $result, $duration ) = @_;
    return { status => "undefined" } if not $result;
    return {
        status        => $OUTPUT_STATUS{ $result->result },
        error_message => $result->output,
        defined $duration
        ? ( duration => int( $duration * 1_000_000_000 ) )
        : (),    # nanoseconds
    };
}

=head1 SEE ALSO

L<https://github.com/masterthought/cucumber-reporting>

L<http://cucumber-reporting.masterthought.net>

L<https://www.relishapp.com/cucumber/cucumber/docs/json-output-formatter>

=cut

1;
