Feature: Match-only testing
  As a test developer I want to be able to assert that
  all steps in my feature are matched without being
  required to run the entire test suite (and spend
  the associated amount of time waiting).

  As a solution to this problem, Pherkin offers the
  ability to run through all steps in features matching
  the steps without executing the step functions.


  Scenario: Test match only function
    Given a step with step function that calls die()
     When there are further steps with associated step functions
     Then I expect all steps to be matched

