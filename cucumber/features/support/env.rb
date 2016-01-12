require 'calabash-cucumber/wait_helpers'
require 'calabash-cucumber/operations'

# These features need to work during a transition away from
# the calabash-common gem.
#
# This guard can be removed when this is closed:
#
# remove calabash-common dependency #922
# https://github.com/calabash/calabash-ios/issues/922
begin
  require "calabash-cucumber/formatters/html"
rescue LoadError => _
  puts "Skipping calabash-cucumber/formatter/html"
end

World(Calabash::Cucumber::Operations)

require 'rspec'

# Pry is not allowed on the Xamarin Test Cloud.  This will force a validation
# error if you mistakenly submit a binding.pry to the Test Cloud.
if !ENV['XAMARIN_TEST_CLOUD']
  require 'pry'
  Pry.config.history.file = '.pry-history'
  require 'pry-nav'
end

