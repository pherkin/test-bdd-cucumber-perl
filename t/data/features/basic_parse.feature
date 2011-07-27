# https://github.com/cucumber/gherkin/tree/master/features
Feature: Basic Parser
  In order to support the creation of BDD tests
  We want to be able to parse simple Gherkin files

  Scenario: Really Simple Parse
    Given the following feature block is parsed:
      """
        Feature: My Ünicode Feature
      """
    Then the document object should have a title of "My Ünicode Feature"
