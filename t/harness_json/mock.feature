Feature: My mock feature

  Scenario: mock failing test
    Given that we have list of items="<items>"
    When calculate count
    Then number of items is "<count>"
    Examples:
      | items     | count |
      | 2,-1,4,55 |     1 |
      | 0,-22,33  |     3 |

  Scenario: mock pending test
    Given that we receive list of items from server
    When calculate count
    Then summary is "55"

  Scenario: mock missing step definition
    Given that this step is missing
    When calculate count
    Then summary is "55"
