Feature: Tags

  Scenario: execute scenarios matching a tag
    # cucumber --tags @foo
    Given a scenario tagged with "@foo"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios tagged with "@foo"
    Then only the first scenario is executed

  Scenario: execute scenarios not matching a tag
    # cucumber --tags ~@bar
    Given a scenario tagged with "@foo"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios not tagged with "@bar"
    Then only the first scenario is executed

  Scenario: execute scenarios matching any of several tags (OR)
    # cucumber --tags @foo,@bar
    Given a scenario tagged with "@bar"
    And a scenario tagged with "@foo"
    And a scenario tagged with "@baz"
    When Cucumber executes scenarios tagged with "@foo" or "@bar"
    Then only the first two scenarios are executed

  Scenario: execute scenarios matching several tags (AND)
    # cucumber --tags @foo --tags @bar
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios tagged with both "@foo" and "@bar"
    Then only the first scenario is executed

  Scenario: execute scenarios not matching any tag (NOT OR NOT)
    # cucumber --tags ~@foo --tags ~@bar
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios not tagged with "@foo" nor "@bar"
    Then only the third scenario is executed

  Scenario: exclude scenarios matching two tags (NOT AND NOT)
    # cucumber --tags ~@foo,~@bar
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@foo"
    When Cucumber executes scenarios not tagged with both "@foo" and "@bar"
    Then only the second, third and fourth scenarios are executed

  Scenario: with tag or without other tag
    # cucumber --tags @foo,~@bar
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@baz"
    And a scenario tagged with "@bar"
    When Cucumber executes scenarios tagged with "@foo" or without "@bar"
    Then only the first two scenarios are executed

  Scenario: with tag but without two other tags
    # cucumber --tags @baz --tags ~@foo --tags ~@bar
    Given a scenario tagged with "@foo" and "@bar"
    And a scenario tagged with "@foo", "@bar" and "@baz"
    And a scenario tagged with "@baz"
    When Cucumber executes scenarios tagged with "@baz" but not with both "@foo" and "@bar"
    Then only the third scenario is executed

  Scenario: execute scenario with tagged feature
    Given a feature tagged with "@foo"
    And a scenario without any tags
    When Cucumber executes scenarios tagged with "@foo"
    Then the scenario is executed
