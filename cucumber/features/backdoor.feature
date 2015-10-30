@backdoor
Feature:  Backdoors
In order make UI testing faster and easier
As a tester
I want a way to get my app into a good shape for testing
and to get some state from my app at runtime

Background: Navigate to the controls tab
  Given the app has launched

@wip
Scenario: Backdoor selector is unknown
  And I call backdoor with an unknown selector
  Then I should see a helpful error message

Scenario: Void return type
  And I call backdoor on a method whose return type is void
  Then I get back <VOID>

Scenario: Primitive return types
  Then I call backdoor on a method that returns BOOL NO
  Then I call backdoor on a method that returns BOOL YES
  Then I call backdoor on a method that returns an int
  Then I call backdoor on a method that returns an unsigned int
  Then I call backdoor on a method that returns a short
  Then I call backdoor on a method that returns a unsigned short
  Then I call backdoor on a method that returns a float
  Then I call backdoor on a method that returns a double
  Then I call backdoor on a method that returns a long double
  Then I call backdoor on a method that returns a c string
  Then I call backdoor on a method that returns a char
  Then I call backdoor on a method that returns an unsigned char
  Then I call backdoor on a method that returns a long
  Then I call backdoor on a method that returns an unsigned long
  Then I call backdoor on a method that returns a long long
  Then I call backdoor on a method that returns an unsigned long
  Then I call backdoor on a method that returns a CGPoint
  Then I call backdoor on a method that returns a CGRect
  Then I call backdoor on a method that returns LPSmokeAlarm struct

Scenario: Pointer return types
  Then I can call backdoor on a method that returns an NSArray
  Then I can call backdoor on a method that returns an NSDictionary
  Then I can call backdoor on a method that returns an NSString

Scenario: Methods with arguments
  Then I call backdoor on a method with primative arguments
  Then I call backdoor on a method with two arguments
  Then I call backdoor on a method with three arguments

