require 'calabash-cucumber/wait_helpers'
require 'calabash-cucumber/operations'

World(Calabash::Cucumber::Operations)

module Calabash
  module Cucumber
    module ServerTestExtensions
      def with_env(var_name, new_value, &block)
        original_value = ENV[var_name]
        begin
          ENV[var_name] = new_value
          block.call
        ensure
          ENV[var_name] = original_value
        end
      end
    end
  end
end

World(Calabash::Cucumber::ServerTestExtensions)

if ENV['XAMARIN_TEST_CLOUD'] != '1'
  require 'pry'
end

# override cucumber `pending` on the XTC
if ENV['XAMARIN_TEST_CLOUD'] == '1'
  module Cucumber
    module RbSupport
      def pending(message = 'TODO')
        raise "PENDING: #{message}"
      end
    end
  end
  World(Cucumber::RbSupport)
end
