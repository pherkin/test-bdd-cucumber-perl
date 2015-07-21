package Test::BDD::Cucumber::TestBuilderDelegator;

# Original fix and investigation all by https://github.com/tomas-zemres - based
# on Test::Tester::Delegate. Original patch here:
#
#   https://github.com/pjlsergeant/test-bdd-cucumber-perl/pull/61
#
# which I have unfortunately butchered in order to understand and adapt it.

# Some modules - like Test::Exception - start off by taking a local reference to
# the Test::Builder singleton:
#
#    my $Tester = Test::Builder->new;
#
# ... which later confounds our efforts to `local`ise $Test::Builder::Test.
# This module provides a wrapper that we can put in to $Test::Builder::Test
# early, and that we can redirect calls to.

use strict;
use warnings;

use vars '$AUTOLOAD';

sub new {
    my ( $classname, $wraps ) = @_;
    return bless { _wraps => $wraps }, $classname;
}

sub AUTOLOAD {
    my ($sub) = $AUTOLOAD =~ /.*::(.*?)$/;
    return if $sub eq "DESTROY";

    my $self = shift;

    # The object we'll be executing against
    my $wraps = $self->{'_wraps'};

    # Get a reference to the original
    my $ref = $wraps->can($sub);

    # Add the wrapped object to the front of @_
    unshift( @_, $wraps );

    # Redispatch; goto replaces the current stack frame, so it's like we were
    # never here...
    goto &$ref;
}

1;
