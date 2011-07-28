Feature: Basic Calculator Functions
  In order to check I've written the Calculator class correctly
  As a developer I want to check some basic operations
  So that I can have confidence in my Calculator class.

  Background:
    Given a usable "Calculator" class

  Scenario: First Key Press on the Display
    Given a new Calculator object
    And having pressed 1
    Then the display should show 1

  Scenario: Several Key Presses on the Display
    Given a new Calculator object
    And having pressed 1 and 2 and 3 and . and 5 and 0
    Then the display should show 123.50

  Scenario: Pressing Clear Wipes the Display
    Given a new Calculator object
    And having pressed 1 and 2 and 3
    And having pressed C
    Then the display should show 0

  Scenario: Basic arithmetic
    Given a new Calculator object
    And having keyed <first>
    And having keyed <operator>
    And having keyed <second>
    And having pressed =
    Then the display should show <result>
    Examples:
      | first | operator | second | result |
      | 5.0   | +        | 5.0    | 10     |
#      | 6     | /        | 3      | 2      |
#      | 10    | *        | 7.550  | 75.5   |
#      | 3     | -        | 10     | -3     |
#      | 0     | 5        | +      | 10     |