require "irb/completion"
require "irb/ext/save-history"
require "benchmark"
require "run_loop"
require "command_runner"

require 'calabash-cucumber/operations'

extend Calabash::Cucumber::Operations

def embed(x,y=nil,z=nil)
  puts "Screenshot at #{x}"
end

AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = '.irb-history'

IRB.conf[:AUTO_INDENT] = true

IRB.conf[:PROMPT][:SERVER] = {
  :PROMPT_I => "SERVER #{Calabash::Cucumber::VERSION}> ",
  :PROMPT_N => "SERVER #{Calabash::Cucumber::VERSION}> ",
  :PROMPT_S => nil,
  :PROMPT_C => "> ",
  :AUTO_INDENT => false,
  :RETURN => "%s\n"
}

IRB.conf[:PROMPT_MODE] = :SERVER

begin
  require 'pry'
  Pry.config.history.file = '.pry-history'
  Pry.config.history.should_save = true
  Pry.config.history.should_load = true
  require 'pry-nav'
rescue LoadError => _

end

APP = File.expand_path("../Products/test-target/app-cal/LPTestTarget.app")

def make_app
  Dir.chdir "../" do
    Bundler.with_clean_env do
      printf "Making the LPTestTarget..."
      CommandRunner.run(["make", "app-cal"], :timeout => 30)
      puts "done!"
    end
  end
  File.exist?(APP)
end

def verbose
  ENV['DEBUG'] = "1"
end

def quiet
  ENV['DEBUG'] = "1"
end

puts ""
puts "#       =>  Useful Methods  <=          #"
puts "> make_app    => make the LPTestTarget"
puts "> verbose     => turn on DEBUG logging"
puts "> quiet       => turn off DEBUG logging"
puts ""


unless File.exist?(APP)
  make_app
end

puts "APP => '#{APP}'"
ENV["APP"] = APP

motd=["Let's get this done!", 'Ready to rumble.', 'Enjoy.', 'Remember to breathe.',
      'Take a deep breath.', "Isn't it time for a break?", 'Can I get you a coffee?',
      'What is a calabash anyway?', 'Smile! You are on camera!', 'Let op! Wild Rooster!',
      "Don't touch that button!", "I'm gonna take this to 11.", 'Console. Engaged.',
      'Your wish is my command.', 'This console session was created just for you.']

puts "The server says: \"#{motd.sample()}\""

