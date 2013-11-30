Feature: Basic Calculator Functions
  In order to check I've written the Calculator class correctly
  As a developer I want to check some basic operations
  So that I can have confidence in my Calculator class.

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

  Scenario: Add as you go
    Given a new Calculator object
    And having pressed 1 and 2 and 3 and + and 4 and 5 and 6 and +
    Then the display should show 579

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
      | 6     | /        | 3      | 2      |
      | 10    | *        | 7.550  | 75.5   |
      | 3     | -        | 10     | -7     |

  Scenario: Separation of calculations
    Given a new Calculator object
    And having successfully performed the following calculations
      | first | operator | second | result |
      | 0.5   | +        | 0.1    | 0.6    |
      | 0.01  | /        | 0.01   | 1      |
      | 10    | *        | 1      | 10     |
    And having pressed 3
    Then the display should show 3

  Scenario: Ticker Tape
    Given a new Calculator object
    And having entered the following sequence
      """
      1 + 2 + 3 + 4 + 5 + 6 -
      100
      * 13 \=\=\= + 2 =
      """
    Then the display should show -1025

  Scenario: Enter number using text
    Given a new Calculator object
    And having keyed __THE_NUMBER_FIVE__
    Then the display should show 5

  Scenario: Enter numbers using text
    Given a new Calculator object
    And having added these numbers
      | number as word      |
      | __THE_NUMBER_FOUR__ |
      | __THE_NUMBER_FIVE__ |
      | __THE_NUMBER_ONE__  |
    Then the display should show 10
    And the display should show __THE_NUMBER_TEN__
