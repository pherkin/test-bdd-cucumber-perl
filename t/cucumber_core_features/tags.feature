Feature: Tags

  Scenario: execute scenarios matching a tag
    Given a scenario tagged with "@foo"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios tagged with "@foo"
    # cucumber --tags @foo
    Then only the first scenario is executed

  Scenario: execute scenarios not matching a tag
    Given a scenario tagged with "@foo"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios not tagged with "@bar"
    # cucumber --tags ~@bar
    Then only the first scenario is executed

  Scenario: execute scenarios matching any of several tags (OR)
    Given a scenario tagged with "@bar"
    And a scenario tagged with "@foo"
    And a scenario tagged with "@baz"
    When Cucumber executes scenarios tagged with "@foo" or "@bar"
    # cucumber --tags @foo,@bar
    Then only the first two scenarios are executed

  Scenario: execute scenarios matching several tags (AND)
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios tagged with both "@foo" and "@bar"
    # cucumber --tags @foo --tags @bar
    Then only the first scenario is executed

  Scenario: execute scenarios not matching any tag (NOT OR NOT)
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios not tagged with "@foo" nor "@bar"
    # cucumber --tags ~@foo --tags ~@bar
    Then only the third scenario is executed

  Scenario: exclude scenarios matching two tags (NOT AND NOT)
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios not tagged with both "@foo" and "@bar"
    # cucumber --tags ~@foo,~@bar
    Then only the second, third and fourth scenarios are executed

  Scenario: with tag or without other tag
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios tagged with "@foo" or without "@bar"
    # cucumber --tags @foo,~@bar
    Then only the first two scenarios are executed

  Scenario: with tag but without two other tags
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@foo", "@bar" and "@baz"
    And a scenario tagged with "@baz"
    When Cucumber executes scenarios tagged with "@baz" but not with both "@foo" and "@bar"
    # cucumber --tags @baz --tags ~@foo --tags ~@bar
    Then only the third scenario is executed

  Scenario: execute scenario with tagged feature
    Given a feature tagged with "@foo"
    And a scenario without any tags
    When Cucumber executes scenarios tagged with "@foo"
    Then the scenario is executed
