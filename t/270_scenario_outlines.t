#!perl

use strict;
use warnings;
use utf8;

use Test::More;

use Test::BDD::Cucumber::Parser;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness::Data;

# If you've taken the time to explicitly declare a Scenario Outline in any
# language, you need to have provided examples

my $feature = eval { Test::BDD::Cucumber::Parser->parse_string(
    <<HEREDOC
# language: th
ความต้องการทางธุรกิจ: Test Feature
	Conditions of satisfaction

	เหตุการณ์:
		กำหนดให้ a passing step called 'foo'
		กำหนดให้ a passing step called '<name>'
        ชุดของตัวอย่าง:
          | name |
          | 1    |

    สรุปเหตุการณ์:
        กำหนดให้ a passing step called 'bar'
        กำหนดให้ a passing step called '<name>'
HEREDOC
) };

my $error = $@;

ok( $error, "A parsing error was caught" );
like( $error, qr/Outline scenario expects/, "Error is about outline scenario" );
like( $error, qr/12\*/, "Error identifies correct start line" );

done_testing();
