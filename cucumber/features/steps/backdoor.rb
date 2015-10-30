
Then(/^I call backdoor on a method that returns a CGSize$/) do
  # Doc step
end

Then(/^I see that CGSize is not fully supported$/) do
  expect(backdoor("backdoorSize")).to be == "CGSize"
end

Then(/^I call backdoor on a method that returns LPSmokeAlarm struct$/) do
  # Doc step
end

Then(/^I see that arbitrary structs are not fully supported$/) do
  expect(backdoor("backdoorSmokeAlarm")).to be == "?"
end

Then(/^void☀ arguments are not handled$/) do
  # Doc step
end

Then(/^primitive pointer arguments like float☀ and int☀ are not handled$/) do
  # Doc step
end

Then(/^NSError☀☀ arguments are not handled$/) do
  # Doc step
end

Then(/^primitive array arguments like int\[\] are not handled$/) do
  # Doc step
end

Then(/^arbitrary struct arguments are not handled$/) do
  # Doc step
end

Then(/^CGSize arguments are not handled$/) do
  # Doc step
end

Then(/^I can pass self as an argument using __self__$/) do
  expect(backdoor("backdoorWithArgSelf:", "__self__")).to be == true
end

Then(/^I can pass nil as an argument using __nil__$/) do
  expect(backdoor("backdoorWithArgNil:", "__nil__")).to be == true
end

And(/^I call backdoor with an unknown selector$/) do
  begin
    backdoor("unknownSelector:", "")
  rescue RuntimeError => e
    puts e
    @backdoor_raised_an_error = true
  end
end

Then(/^I should see a helpful error message$/) do
  expect(@backdoor_raised_an_error).to be == true
end

When(/^I call backdoor on a method with a void return type$/) do
  @backdoor_result = backdoor("backdoorThatReturnsVoid")
end

Then(/^I get back <VOID>$/) do
  expect(@backdoor_result).to be == "<VOID>"
end

When(/^I call backdoor on a method that returns long double$/) do
  # Empty step for documentation
  @unknown_encoding_method = "backdoorLDouble"
end

Then(/^I get an unknown encoding exception$/) do
  expect do
    backdoor(@unknown_encoding_method)
  end.to raise_error RuntimeError, /Error: selector returns an unknown encoding/
end

Then(/^backdoors that return NSDate return a ruby string$/) do
  actual = backdoor("backdoorDate")
  expect(actual).to be_a_kind_of(String)
  expect(actual).not_to be == ""
end

Then(/^I call backdoor on a method that returns BOOL (NO|YES)$/) do |value|
  if value == "NO"
    expected = false
    method = "backdoorNO"
  else
    expected = true
    method = "backdoorYES"
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns an? (int|unsigned int|NSInteger|NSUInteger)$/) do |type|
  case type
  when "int"
    method = "backdoorInt"
    expected = -17
  when "unsigned int"
    method = "backdoorUInt"
    expected = 17
  when "NSInteger"
    method = "backdoorNSInteger"
    expected = -17
  when "NSUInteger"
    method = "backdoorNSUInteger"
    expected = 17
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns an? (short|unsigned short)$/) do |type|
  case type
  when "short"
    method = "backdoorShort"
    expected = -1
  when "unsigned short"
    method = "backdoorUShort"
    expected = 1
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns an? (float|double|CGFloat)$/) do |type|
  case type
  when "float"
    method = "backdoorFloat"
    expected = 0.314
  when "double"
    method = "backdoorDouble"
    expected = 54.46
  when "CGFloat"
    method = "backdoorCGFloat"
    expected = 54.46
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns an? (char|unsigned char)$/) do |type|
  case type
  when "char"
    method = "backdoorChar"
    expected = "c"
  when "unsigned char"
    method = "backdoorUChar"
    expected = "C"
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns a c string$/) do
  expect(backdoor("backdoorCharStar")).to be == "char *"
end

Then(/^I call backdoor on a method that returns a const char star$/) do
  expect(backdoor("backdoorConstCharStar")).to be == "const char *"
end

Then(/^I call backdoor on a method that returns an? (long|long long)$/) do |type|
  case type
  when "long"
    method = "backdoorLong"
    expected = -42
  when "long long"
    method = "backdoorLongLong"
    expected = -43
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns an unsigned (long|long long)$/) do |type|
  case type
  when "long"
    method = "backdoorULong"
    expected = 42
  when "long long"
    method = "backdoorULongLong"
    expected = 43
  end
  expect(backdoor(method)).to be == expected
end

Then(/^I call backdoor on a method that returns a CGPoint$/) do
  hash = backdoor("backdoorPoint")
  expect(hash["X"]).to be == 0
  expect(hash["Y"]).to be == 0
end

Then(/^I call backdoor on a method that returns a CGRect$/) do
  hash = backdoor("backdoorRect")
  expect(hash["X"]).to be == 0
  expect(hash["Y"]).to be == 0
  expect(hash["Height"]).to be == 0
  expect(hash["Width"]).to be == 0
end

Then(/^I call backdoor on a method that returns an NSNumber$/) do
  expect(backdoor("backdoorNumber")).to be == 11
end

Then(/^I call backdoor on a method that returns an NSArray$/) do
  expect(backdoor("backdoorArray")).to be == ["a", "b", 3]
end

Then(/^I call backdoor on a method that returns an NSDictionary$/) do
  expected = {"a" => 0, "b" => 1, "c" => nil}
  expect(backdoor("backdoorDictionary")).to be == expected
end

Then(/^I call backdoor on a method that returns an NSString$/) do
  expect(backdoor("backdoorString")).to be == "string"
end

Then(/^I call backdoor on a method with (one|two|three) pointer arguments?$/) do |number|
  case number
  when "one"
    method = "backdoorWithString:"
    args = ["string"]
    expected = "string"
  when "two"
    method = "backdoorWithString:array:"
    args = ["string", [1, 2, 3]]
    expected = args.dup
  when "three"
    method = "backdoorWithString:array:dictionary:"
    args = ["string", [1, 2, 3], {:key => "value"}]
    expected = {
      "string" => "string",
      "array" => [1, 2, 3],
      "dictionary" => {"key" => "value"}
    }
  end

  expect(backdoor(method, *args)).to be == expected
end

Then(/I call backdoor on a method with a BOOL argument$/) do
  expect(backdoor("backdoorWithBOOL_YES:", true)).to be == true
  expect(backdoor("backdoorWithBOOL_NO:", false)).to be == true
end

Then(/I call backdoor on a method with a bool argument$/) do
  expect(backdoor("backdoorWithBool_true:", true)).to be == true
  expect(backdoor("backdoorWithBool_false:", false)).to be == true
end

Then(/I call backdoor on a method with an? (NSInteger|NSUInteger) argument$/) do |type|
  case type
  when "NSInteger"
    method = "backdoorWithNSInteger:"
    args = [-17]
  when "NSUInteger"
    method = "backdoorWithNSUInteger:"
    args = [17]
  end
  expect(backdoor(method, *args)).to be == true
end

Then(/I call backdoor on a method with an? (unsigned short|short) argument$/) do |type|
  case type
  when "short"
    method = "backdoorWithShort:"
    args = [-1]
  when "unsigned short"
    method = "backdoorWithUShort:"
    args = [1]
  end
  expect(backdoor(method, *args)).to be == true
end

Then(/I call backdoor on a method with a (CGFloat|double|float) argument$/) do |type|
  args = [54.46]
  case type
  when "CGFloat"
    method = "backdoorWithCGFloat:"
  when "double"
    method = "backdoorWithDouble:"
  when "float"
    method = "backdoorWithFloat:"
    args = [0.314];
  end
  expect(backdoor(method, *args)).to be == true
end

Then(/I call backdoor on a method with an? (unsigned char|char) argument$/) do |type|
  case type
  when "char"
    method = "backdoorWithChar:"
    args = ["c"]
  when "unsigned char"
    method = "backdoorWithUChar:"
    args = ["C"]
  end
  expect(backdoor(method, *args)).to be == true
end
Then(/I call backdoor on a method with an? (unsigned long|long) argument$/) do |type|
  case type
  when "long"
    method = "backdoorWithLong:"
    args = [-42]
  when "unsigned long"
    method = "backdoorWithULong:"
    args = [42]
  end
  expect(backdoor(method, *args)).to be == true
end

Then(/I call backdoor on a method with an? (unsigned long|long) long argument$/) do |type|
  case type
  when "long"
    method = "backdoorWithLongLong:"
    args = [-43]
  when "unsigned long"
    method = "backdoorWithULongLong:"
    args = [43]
  end
  expect(backdoor(method, *args)).to be == true
end

Then(/I call backdoor on a method with a c string argument$/) do
  expect(backdoor("backdoorWithArgCharStar:", "char *")).to be == true
end

Then(/I call backdoor on a method with a const char star argument$/) do
  args = ["const char *"]
  expect(backdoor("backdoorWithArgConstCharStar:", *args)).to be == true
end

Then(/I call backdoor on a method with a CGPoint argument$/) do
  args = [{"x" => 1, "y" => 2}]
  expect(backdoor("backdoorWithArgCGPoint:", *args)).to be == true
end

Then(/I call backdoor on a method with a CGRect argument$/) do
  args = [{"x" => 1, "y" => 2, "width" => 3, "height" => 4}]
  expect(backdoor("backdoorWithArgCGRect:", *args)).to be == true
end

Then(/I call backdoor on a method with a Class argument$/) do
  expect(backdoor("backdoorWithArgClass:", "NSArray")).to be == true
  expect(backdoor("backdoorWithArgClass:", "NSString")).to be == false
end

