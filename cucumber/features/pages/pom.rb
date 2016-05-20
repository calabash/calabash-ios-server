module POM
  require "calabash-cucumber/ibase"

  class HomePage < Calabash::IBase

    def my_buggy_method
      screenshot_and_raise 'Hey!'
    end

  end
end

