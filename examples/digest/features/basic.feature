# Somehow I don't see this replacing the other tests this module has...
Feature: Simple tests of Digest.pm
  As a developer planning to use Digest.pm
  I want to test the basic functionality of Digest.pm
  In order to have confidence in it

  Background:
    Given a usable "Digest" class

  Scenario: Check MD5
    Given a Digest MD5 object
    When I've added "foo bar baz" to the object
    And I've added "bat ban shan" to the object
    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"
    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"

  Scenario: Check SHA-1
    Given a Digest SHA-1 object
    When I've added "<data>" to the object
    Then the hex output is "<output>"
    Examples:
      | data | output   |
      | foo  | 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33 |
      | bar  | 62cdb7020ff920e5aa642c3d4066950dd1f01f4d |
      | baz  | bbe960a25ea311d21d40669e93df2003ba9b90a2 |

  Scenario: MD5 longer data
    Given a Digest MD5 object
    When I've added the following to the object
      """
      Here is a chunk of text that works a bit like a HereDoc. We'll split
      off indenting space from the lines in it up to the indentation of the
      first \"\"\"
      """
    Then the hex output is "75ad9f578e43b863590fae52d5d19ce6"

