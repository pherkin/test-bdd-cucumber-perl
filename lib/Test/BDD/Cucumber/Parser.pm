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

use Test::BDD::Cucumber::Model::Dataset;
use Test::BDD::Cucumber::Model::Document;
use Test::BDD::Cucumber::Model::Feature;
use Test::BDD::Cucumber::Model::Scenario;
use Test::BDD::Cucumber::Model::Step;
use Test::BDD::Cucumber::Model::TagSpec;
use Test::BDD::Cucumber::I18n qw(langdef);
use Test::BDD::Cucumber::Errors qw/parse_error_from_line/;

# https://github.com/cucumber/cucumber/wiki/Multiline-Step-Arguments
# https://github.com/cucumber/cucumber/wiki/Scenario-outlines

sub parse_string {
    my ( $class, $string ) = @_;

    return $class->_construct(
        Test::BDD::Cucumber::Model::Document->new(
            {
                content => $string
            }
        )
    );
}

sub parse_file {
    my ( $class, $string ) = @_;
    {
        local $/;
        open(my $in, '<', $string) or die $?;
        binmode $in, 'utf8';
        return $class->_construct(
            Test::BDD::Cucumber::Model::Document->new(
                {
                    content => <$in>,
                    filename => '' . $string
                }
            )
        );
    }
}

sub _construct {
    my ( $class, $document ) = @_;

    my $feature =
      Test::BDD::Cucumber::Model::Feature->new( { document => $document } );
    my @lines = $class->_remove_next_blanks( @{ $document->lines } );

    $feature->language( $class->_extract_language( \@lines ) );

    my $langdef = langdef( $feature->language );
    my $self = bless {
        langdef => $langdef,
        _construct_matchers( $langdef )
    }, $class;

    $self->_extract_scenarios(
        $self->_extract_conditions_of_satisfaction(
            $self->_extract_feature_name( $feature, @lines )
        )
    );

    return $feature;
}

sub _construct_matchers {
    my ($l) = @_;
    my $step_line_kw_cont =
        join('|', map { $l->{$_} } qw/given and when then but/);
    my $step_line_kw_first =
        join('|', map { $l->{$_} } qw/given when then/);
    my $scenario_line_kw =
        join('|', map { $l->{$_} } qw/background scenario scenarioOutline/);

    return (
        _step_line_first => qr/^($step_line_kw_first)(.+)/,
        _step_line_cont  => qr/^($step_line_kw_cont)(.+)/,
        _feature_line    => qr/^($l->{feature}): (.+)/,
        _scenario_line   => qr/^($scenario_line_kw): ?(.*)?/,
        _examples_line   => qr/^($l->{examples}): ?(.+)?$/,
        _table_line      => qr/^\s*\|/,
        _tags_line       => qr/\@([^\s]+)/,
        );
}

sub _is_step_line {
    my ($self, $continuation, $line) = @_;

    if ($continuation) {
        return $line =~ $self->{_step_line_cont};
    }
    else {
        return $line =~ $self->{_step_line_first};
    }
}

sub _is_feature_line {
    my ($self, $line) = @_;

    return $line =~ $self->{_feature_line};
}

sub _is_scenario_line {
    my ($self, $line) = @_;

    return $line =~ $self->{_scenario_line};
}

sub _is_table_line {
    my ($self, $line) = @_;

    return $line =~ $self->{_table_line};
}

sub _is_tags_line {
    my ($self, $line) = @_;

    return $line =~ $self->{_tags_line};
}

sub _is_examples_line {
    my ($self, $line) = @_;

    return $line =~ $self->{_examples_line};
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

        if ( my ($keyword, $name) =
             $self->_is_feature_line( $line->content ) ) {
            $feature->name($name);
            $feature->keyword_original($keyword);
            $feature->name_line($line);
            $feature->tags( \@feature_tags );

            last;

            # Feature-level tags
        } elsif ( $line->content =~ m/^\s*\@\w/ ) {
            my @tags = $line->content =~ m/\@([^\s]+)/g;
            push( @feature_tags, @tags );

        } else {
            die parse_error_from_line(
                'Malformed feature line (expecting: /^(?:'
                  . $self->{langdef}->{feature}
                  . '): (.+)/',
                $line
            );
        }
    }

    return $feature, $self->_remove_next_blanks(@lines);
}

sub _extract_conditions_of_satisfaction {
    my ( $self, $feature, @lines ) = @_;

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment || $line->is_blank;

        if ( $self->_is_scenario_line( $line->content )
             or $self->_is_tags_line( $line->content ) ) {
            unshift( @lines, $line );
            last;
        } else {
            push( @{ $feature->satisfaction }, $line );
        }
    }

    return $feature, $self->_remove_next_blanks(@lines);
}

sub _finish_scenario {
    my ($self, $feature, $line) = @_;
    # Catch Scenario outlines without examples
    if ( @{ $feature->scenarios } ) {
        my $last_scenario = $feature->scenarios->[-1];
        if ( $last_scenario->keyword_original =~ m/^($self->{langdef}->{scenarioOutline})/
             && !@{ $last_scenario->data } )
        {
            die parse_error_from_line(
                "Outline scenario expects 'Examples:' section",
                $line || $last_scenario->line );
        }
    }
 }

sub _extract_scenarios {
    my ( $self, $feature, @lines ) = @_;
    my $scenarios = 0;
    my $langdef   = $self->{langdef};
    my @tags;

    while ( my $line = shift(@lines) ) {
        next if $line->is_comment || $line->is_blank;

        if ( my ( $type, $name ) =
             $self->_is_examples_line( $line->content ) ) {

            die q{'Examples:' line before scenario definition}
                unless @{$feature->scenarios};

            my $dataset = Test::BDD::Cucumber::Model::Dataset->new(
                ( $name ? ( name => $name ) : () ),
                tags => ( @tags ?
                          [ @{ $feature->scenarios->[-1]->tags }, @tags ]
                          # Reuse the ref to the scenario tags to allow
                          # detecting 'no dataset tags' in ::Scenario
                          : $feature->scenarios->[-1]->tags ),
                line => $line,
                );
            @tags = ();
            if (@{$feature->scenarios->[-1]->datasets}) {
                my $prev_ds = $feature->scenarios->[-1]->datasets->[0];
                my $prev_ds_cols = join '|', keys %{$prev_ds->data->[0]};
                my $cur_ds_cols = join '|', keys %{$dataset->data->[0]};
                die parse_error_from_line(
                    q{'Examples:' not in line with previous 'Examples:'}, $line )
                    if $prev_ds_cols ne $cur_ds_cols;
            }
            push @{$feature->scenarios->[-1]->datasets}, $dataset;

            @lines = $self->_extract_examples_description( $dataset, @lines );
            @lines = $self->_extract_table( 6, $dataset,
                                            $self->_remove_next_blanks(@lines) );
        }
        elsif ( ( $type, $name ) =
                $self->_is_scenario_line( $line->content ) ) {

            $self->_finish_scenario( $feature, $line );

            # Only one background section, and it must be the first
            if ( $scenarios++ && $type =~ m/^($langdef->{background})/ ) {
                die parse_error_from_line(
                    "Background not allowed after scenarios", $line );
            }

            # Create the scenario
            my $scenario = Test::BDD::Cucumber::Model::Scenario->new(
                {
                    ( $name ? ( name => $name ) : () ),
                    background       => $type =~ m/^($langdef->{background})/ ? 1 : 0,
                    keyword          =>
                        ($type =~ m/^($langdef->{background})/ ? 'Background'
                         : ($type =~ m/^($langdef->{scenarioOutline})/
                            ? 'Scenario Outline' : 'Scenario')),
                    keyword_original => $type,
                    line             => $line,
                    tags             => [ @{ $feature->tags }, @tags ]
                }
            );
            @tags = ();

            # Attempt to populate it
            @lines = $self->_extract_scenario_description($scenario, @lines);
            @lines = $self->_extract_steps( $feature, $scenario, @lines );

            if ( $type =~ m/^($langdef->{background})/ ) {
                $feature->background($scenario);
            } else {
                push( @{ $feature->scenarios }, $scenario );
            }

            # Scenario-level tags
        } elsif ( $line->content =~ m/^\s*\@\w/ ) {
            push @tags, ( $line->content =~ m/\@([^\s]+)/g );

        } else {
            die parse_error_from_line( "Malformed scenario line", $line );
        }
    }

    $self->_finish_scenario( $feature );
    return $feature, $self->_remove_next_blanks(@lines);
}

my $warned_mixed_comments = 0;

sub _extract_steps {
    my ( $self, $feature, $scenario, @lines ) = @_;

    my $langdef   = $self->{langdef};
    my @givens    = split( /\|/, $langdef->{given} );
    my $last_verb = $givens[-1];
    my $last_line_was_comment = 0;


    my ( $verb, $text );
    while ( @lines and
            ($lines[0]->is_comment
             or ($verb, $text) = $self->_is_step_line( 1, $lines[0]->content ) ) ) {
        my $line = shift @lines;
        if ($line->is_comment) {
            $last_line_was_comment = 1;
            next;
        }

        if ($last_line_was_comment) {
            # don't issue this warning if the comment is after
            warn 'Mixing comments and steps is deprecated: not allowed in Gherkin'
                unless $warned_mixed_comments;
            $warned_mixed_comments = 1;
        }

        my $original_verb = $verb;
        $verb = 'Given' if $verb =~ m/^($langdef->{given})$/;
        $verb = 'When'  if $verb =~ m/^($langdef->{when})$/;
        $verb = 'Then'  if $verb =~ m/^($langdef->{then})$/;
        $verb = $last_verb
            if $verb =~ m/^($langdef->{and})$/
            or $verb =~ m/^($langdef->{but}$)/;
        $last_verb = $verb;

        # Remove the ending space for languages that
        # have it, for backward compatibility
        $original_verb =~ s/ $//;
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
    }

    return $self->_remove_next_blanks(@lines);
}


sub _extract_examples_description {
    my ( $self, $examples, @lines ) = @_;

    while ( my $line = shift @lines ) {
        next if $line->is_comment;

        my $content = $line->content;
        return ( $line, @lines )
            if $self->_is_table_line( $content )
               or $self->_is_examples_line( $content )
               or $self->_is_tags_line( $content )
               or $self->_is_scenario_line( $content );

        push @{$examples->description}, $line;
    }

    return @lines;
}

sub _extract_scenario_description {
    my ( $self, $scenario, @lines ) = @_;

    while ( @lines
            and ($lines[0]->is_comment
                 or (not $self->_is_step_line(0, $lines[0]->content)
                     and not $self->_is_examples_line($lines[0]->content)
                     and not $self->_is_tags_line($lines[0]->content)
                     and not $self->_is_scenario_line($lines[0]->content) ) )
        ) {
        push @{$scenario->description}, shift(@lines);
    }

    return @lines;
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
            return $self->_remove_next_blanks(@lines);
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
            die parse_error_from_line( "Inconsistent number of rows in table",
                $line )
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
    my @atoms = split( /(?<!\\)\|/, $string );
    shift(@atoms);
    return map {
        my $atom = $_;
        $atom =~ s/^\s+//;
        $atom =~ s/\s+$//;
        $atom =~ s/\\(.)/$1/g;
        $atom
    } @atoms;
}

1;

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 LICENSE

Copyright 2011-2016, Peter Sergeant; Licensed under the same terms as Perl

=cut
