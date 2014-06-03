package Test::BDD::Cucumber::Parser;

=head1 NAME

Test::BDD::Cucumber::Parser - Parse Feature files

=head1 DESCRIPTION

Parse Feature files in to a set of data classes

=head1 SYNOPSIS

 # Returns a Test::BDD::Cucumber::Model::Feature object
 my $feature = Test::BDD::Cucumber::Parser->parse_file(
    't/data/features/basic_parse.feature' );

=head1 METHODS

=head2 parse_string

=head2 parse_file

Both methods accept a single string as their argument, and return a
L<Test::BDD::Cucumber::Model::Feature> object on success.

=cut

use strict;
use warnings;

use Ouch;
use File::Slurp;

use Test::BDD::Cucumber::Model::Document;
use Test::BDD::Cucumber::Model::Feature;
use Test::BDD::Cucumber::Model::Scenario;
use Test::BDD::Cucumber::Model::Step;
use Test::BDD::Cucumber::Model::TagSpec;
use Test::BDD::Cucumber::I18n qw(langdef);

# https://github.com/cucumber/cucumber/wiki/Multiline-Step-Arguments
# https://github.com/cucumber/cucumber/wiki/Scenario-outlines

sub parse_string {
    my ( $class, $string, $tag_scheme ) = @_;

    return $class->_construct(
        Test::BDD::Cucumber::Model::Document->new(
            {
                content => $string
            }
        ),
        $tag_scheme
    );
}

sub parse_file {
    my ( $class, $string, $tag_scheme ) = @_;
    return $class->_construct(
        Test::BDD::Cucumber::Model::Document->new(
            {
                content =>
                  scalar( read_file( $string, { binmode => ':utf8' } ) ),
                filename => $string
            }
        ),
        $tag_scheme
    );
}

sub _construct {
    my ( $class, $document, $tag_scheme ) = @_;

    my $feature =
      Test::BDD::Cucumber::Model::Feature->new( { document => $document } );
    my @lines = $class->_remove_next_blanks( @{ $document->lines } );

    $feature->language( $class->_extract_language( \@lines ) );

    my $self = { langdef => langdef( $feature->language ) };
    bless $self, $class;

    $self->_extract_scenarios(
        $self->_extract_conditions_of_satisfaction(
            $self->_extract_feature_name( $feature, @lines )
        )
    );

    return $feature;
}

sub _extract_language {
    my ( $self, $lines ) = @_;

# return default language if we don't see the language directive on the first line
    return 'en' unless $lines->[0]->raw_content =~ m{^\s*#\s*language:\s+(.+)$};

    # remove the language directive if we saw it ...
    shift @$lines;

    # ... and return the language it declared
    return $1;
}

sub _remove_next_blanks {
    my ( $self, @lines ) = @_;
    while ( $lines[0] && $lines[0]->is_blank ) {
        shift(@lines);
    }
    return @lines;
}

sub _extract_feature_name {
    my ( $self, $feature, @lines ) = @_;
    my @feature_tags = ();

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment;
        last if $line->is_blank;

        if ( $line->content =~ m/^(?:$self->{langdef}->{feature}): (.+)/ ) {
            $feature->name($1);
            $feature->name_line($line);
            $feature->tags( \@feature_tags );

            last;

            # Feature-level tags
        } elsif ( $line->content =~ m/^\s*\@\w/ ) {
            my @tags = $line->content =~ m/\@([^\s]+)/g;
            push( @feature_tags, @tags );

        } else {
            ouch 'parse_error', "Malformed feature line", $line;
        }
    }

    return $feature, $self->_remove_next_blanks(@lines);
}

sub _extract_conditions_of_satisfaction {
    my ( $self, $feature, @lines ) = @_;

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment || $line->is_blank;

        my $langdef = $self->{langdef};
        if ( $line->content =~
            m/^((?:$langdef->{background}):|(?:$langdef->{scenario}):|@)/ )
        {
            unshift( @lines, $line );
            last;
        } else {
            push( @{ $feature->satisfaction }, $line );
        }
    }

    return $feature, $self->_remove_next_blanks(@lines);
}

sub _extract_scenarios {
    my ( $self, $feature, @lines ) = @_;
    my $scenarios = 0;
    my @scenario_tags;

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment || $line->is_blank;

        my $langdef = $self->{langdef};
        if ( $line->content =~
m/^((?:$langdef->{background})|(?:$langdef->{scenario}))(?: Outline)?: ?(.+)?/
          )
        {
            my ( $type, $name ) = ( $1, $2 );

            # Only one background section, and it must be the first
            if ( $scenarios++ && $type =~ m/^($langdef->{background})/ ) {
                ouch 'parse_error', "Background not allowed after scenarios",
                  $line;
            }

            # Create the scenario
            my $scenario = Test::BDD::Cucumber::Model::Scenario->new(
                {
                    ( $name ? ( name => $name ) : () ),
                    background => $type =~ m/^($langdef->{background})/ ? 1 : 0,
                    line => $line,
                    tags => [ @{ $feature->tags }, @scenario_tags ]
                }
            );
            @scenario_tags = ();

            # Attempt to populate it
            @lines = $self->_extract_steps( $feature, $scenario, @lines );

            if ( $type =~ m/^($langdef->{background})/ ) {
                $feature->background($scenario);
            } else {
                push( @{ $feature->scenarios }, $scenario );
            }

            # Scenario-level tags
        } elsif ( $line->content =~ m/^\s*\@\w/ ) {
            my @tags = $line->content =~ m/\@([^\s]+)/g;
            push( @scenario_tags, @tags );

        } else {
            ouch 'parse_error', "Malformed scenario line", $line;
        }
    }

    return $feature, $self->_remove_next_blanks(@lines);
}

sub _extract_steps {
    my ( $self, $feature, $scenario, @lines ) = @_;

    my $langdef   = $self->{langdef};
    my @givens    = split( /\|/, $langdef->{given} );
    my $last_verb = $givens[-1];

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment;
        last if $line->is_blank;

        # Conventional step?
        if ( $line->content =~
m/^((?:$langdef->{given})|(?:$langdef->{and})|(?:$langdef->{when})|(?:$langdef->{then})|(?:$langdef->{but})) (.+)/
          )
        {
            my ( $verb, $text ) = ( $1, $2 );
            my $original_verb = $verb;
            $verb = 'Given' if $verb =~ m/^($langdef->{given})$/;
            $verb = 'When'  if $verb =~ m/^($langdef->{when})$/;
            $verb = 'Then'  if $verb =~ m/^($langdef->{then})$/;
            $verb = $last_verb
              if $verb =~ m/^($langdef->{and})$/
              or $verb =~ m/^($langdef->{but}$)/;
            $last_verb = $verb;

            my $step = Test::BDD::Cucumber::Model::Step->new(
                {
                    text          => $text,
                    verb          => $verb,
                    line          => $line,
                    verb_original => $original_verb,
                }
            );

            @lines =
              $self->_extract_step_data( $feature, $scenario, $step, @lines );

            push( @{ $scenario->steps }, $step );

            # Outline data block...
        } elsif ( $line->content =~ m/^($langdef->{examples}):$/ ) {
            return $self->_extract_table( 6, $scenario,
                $self->_remove_next_blanks(@lines) );
        } else {
            warn $line->content;
            ouch 'parse_error', "Malformed step line", $line;
        }
    }

    return $self->_remove_next_blanks(@lines);
}

sub _extract_step_data {
    my ( $self, $feature, $scenario, $step, @lines ) = @_;
    return unless @lines;

    if ( $lines[0]->content eq '"""' ) {
        return $self->_extract_multiline_string( $feature, $scenario, $step,
            @lines );
    } elsif ( $lines[0]->content =~ m/^\s*\|/ ) {
        return $self->_extract_table( 6, $step, @lines );
    } else {
        return @lines;
    }

}

sub _extract_multiline_string {
    my ( $self, $feature, $scenario, $step, @lines ) = @_;

    my $data   = '';
    my $start  = shift(@lines);
    my $indent = $start->indent;

    # Check we still have the minimum indentation
    while ( my $line = shift(@lines) ) {

        if ( $line->content eq '"""' ) {
            $step->data($data);
            return @lines;
        }

        my $content = $line->content_remove_indentation($indent);

        # Unescape it
        $content =~ s/\\(.)/$1/g;
        push( @{ $step->data_as_strings }, $content );
        $content .= "\n";
        $data .= $content;
    }

    return;
}

sub _extract_table {
    my ( $self, $indent, $target, @lines ) = @_;
    my @columns;

    my $data = [];
    $target->data($data);

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment;
        return ( $line, @lines ) if index( $line->content, '|' );

        my @rows = $self->_pipe_array( $line->content );
        if ( $target->can('data_as_strings') ) {
            my $t_content = $line->content;
            $t_content =~ s/^\s+//;
            push( @{ $target->data_as_strings }, $t_content );
        }

        if (@columns) {
            ouch 'parse_error', "Inconsistent number of rows in table", $line
              unless @rows == @columns;
            $target->columns( [@columns] ) if $target->can('columns');
            my $i = 0;
            my %data_hash = map { $columns[ $i++ ] => $_ } @rows;
            push( @$data, \%data_hash );
        } else {
            @columns = @rows;
        }
    }

    return;
}

sub _pipe_array {
    my ( $self, $string ) = @_;
    my @atoms = split( /\|/, $string );
    shift(@atoms);
    return map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } @atoms;
}

1;

=head1 ERROR HANDLING

L<Test::BDD::Cucumber> uses L<Ouch> for exception handling. Errors originating in this
class tend to have a code of C<parse_error> and a L<Test::BDD::Cucumber::Model::Line>
object for data.

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011, Peter Sergeant; Licensed under the same terms as Perl

=cut
