Feature: Multiple Scenarios
  As a developer using Test::BDD::Cucumber,
  I want to ensure that I can use multiple Scenarios in a Feature.

    Scenario: First test
        Given a Digest MD5 object
         When I add "foo" to the object
          And I add "bar" to the object
         Then the results look like
                | method    | output                           |
                | hexdigest | 3858f62230ac3c915f300c664312c63f |
                | b64digest | 1B2M2Y8AsgTpgAmY7PhCfg           |

    Scenario: Last step with multiline string
        Given a Digest MD5 object
         When I add "foo" to the object
          And I add "bar" to the object
         Then the hexdigest looks like:
                """
                3858f62230ac3c915f300c664312c63f
                """
          And the b64digest looks like:
                """
                1B2M2Y8AsgTpgAmY7PhCfg
                """

    Scenario: First test all over again
        Given a Digest MD5 object
         When I add "foo" to the object
          And I add "bar" to the object
         Then the results look like
                | method    | output                           |
                | hexdigest | 3858f62230ac3c915f300c664312c63f |
                | b64digest | 1B2M2Y8AsgTpgAmY7PhCfg           |
