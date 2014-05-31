package Test::DumpFeature;

use strict;
use warnings;

sub dump_feature {
    my $feature = shift;
    return {
        name => $feature->name,
        line => $feature->name_line->number,
        satisfaction =>
          [ map { $_->content } @{ $feature->satisfaction || [] } ],
        scenarios => [ map { dump_scenario($_) } @{ $feature->scenarios } ]
    };
}

sub dump_scenario {
    my $scenario = shift;
    return {
        name       => $scenario->name,
        line       => $scenario->line->number,
        data       => $scenario->data,
        background => $scenario->background,
        steps      => [ map { dump_step($_) } @{ $scenario->steps } ]
    };
}

sub dump_step {
    my $step = shift;
    return {
        verb          => $step->verb,
        text          => $step->text,
        data          => $step->data,
        line          => $step->line->number,
        verb_original => $step->verb_original
    };
}

1;
