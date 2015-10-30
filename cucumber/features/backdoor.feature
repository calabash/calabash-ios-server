@backdoor
@no_relaunch
Feature:  Backdoors
In order make UI testing faster and easier
As a tester
I want a way to get my app into a good shape for testing
and to get some state from my app at runtime

Background: Launch the app
  Given the app has launched

@unhandled_structs
Scenario:  Struct return type
  When I call backdoor on a method that returns a CGSize
  Then I see that CGSize is not fully supported
  When I call backdoor on a method that returns LPSmokeAlarm struct
  Then I see that arbitrary structs are not fully supported

# ☀  <== * ; Gherkin can not handle * in step names.
# For example, void\* does not work - * is not escaped
@unhandle_arguments
Scenario: Unhandled arguments
  Then void☀ arguments are not handled
  And primitive pointer arguments like float☀ and int☀ are not handled
  And NSError☀☀ arguments are not handled
  And primitive array arguments like int[] are not handled
  And arbitrary struct arguments are not handled
  And CGSize arguments are not handled

Scenario: Backdoor selector is unknown
  When I call backdoor with an unknown selector
  Then I should see a helpful error message

@void
Scenario: Void return type
  When I call backdoor on a method with a void return type
  Then I get back <VOID>

@unknown_encoding
Scenario: Long double retrun type is not supported
  When I call backdoor on a method that returns long double
  Then I get an unknown encoding exception

@date
Scenario: NSDate is returned as a string
  Then backdoors that return NSDate return a ruby string

@self
Scenario: Passing self as an argument
  Then I can pass self as an argument using __self__

@nil
Scenario: Passing nil as an argument
  Then I can pass nil as an argument using __nil__

@primitive
Scenario: Primitive return types
  Then I call backdoor on a method that returns BOOL NO
  Then I call backdoor on a method that returns BOOL YES
  Then I call backdoor on a method that returns an int
  Then I call backdoor on a method that returns an unsigned int
  Then I call backdoor on a method that returns an NSInteger
  Then I call backdoor on a method that returns an NSUInteger
  Then I call backdoor on a method that returns a short
  Then I call backdoor on a method that returns a unsigned short
  Then I call backdoor on a method that returns a float
  Then I call backdoor on a method that returns a double
  Then I call backdoor on a method that returns a CGFloat
  Then I call backdoor on a method that returns a char
  Then I call backdoor on a method that returns an unsigned char
  Then I call backdoor on a method that returns a c string
  Then I call backdoor on a method that returns a const char star
  Then I call backdoor on a method that returns a long
  Then I call backdoor on a method that returns an unsigned long
  Then I call backdoor on a method that returns a long long
  Then I call backdoor on a method that returns an unsigned long
  Then I call backdoor on a method that returns a CGPoint
  Then I call backdoor on a method that returns a CGSize
  Then I call backdoor on a method that returns a CGRect

@pointer
Scenario: Pointer return types
  Then I call backdoor on a method that returns an NSNumber
  Then I call backdoor on a method that returns an NSArray
  Then I call backdoor on a method that returns an NSDictionary
  Then I call backdoor on a method that returns an NSString

@pointer
Scenario: Methods with pointer arguments
  Then I call backdoor on a method with one pointer argument
  Then I call backdoor on a method with two pointer arguments
  Then I call backdoor on a method with three pointer arguments

@primitive
Scenario: Methods with primative arguments
  Then I call backdoor on a method with a BOOL argument
  Then I call backdoor on a method with a bool argument
  Then I call backdoor on a method with an NSInteger argument
  Then I call backdoor on a method with an NSUInteger argument
  Then I call backdoor on a method with a short argument
  Then I call backdoor on a method with an unsigned short argument
  Then I call backdoor on a method with a CGFloat argument
  Then I call backdoor on a method with a double argument
  Then I call backdoor on a method with a float argument
  Then I call backdoor on a method with a char argument
  Then I call backdoor on a method with an unsigned char argument
  Then I call backdoor on a method with a long argument
  Then I call backdoor on a method with a unsigned long argument
  Then I call backdoor on a method with a long long argument
  Then I call backdoor on a method with a unsigned long long argument
  Then I call backdoor on a method with a c string argument
  Then I call backdoor on a method with a const char star argument
  Then I call backdoor on a method with a CGPoint argument
  Then I call backdoor on a method with a CGRect argument
  Then I call backdoor on a method with a Class argument

