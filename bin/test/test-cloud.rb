#!/usr/bin/env ruby

require "luffa"
require "bundler"

Luffa.unix_command("make clean")
Luffa.unix_command("make ipa-cal")

Dir.chdir("cucumber") do
  Bundler.with_clean_env do
    Luffa.unix_command("bundle update")
    Luffa.unix_command("bundle exec briar xtc b6514a95")
  end
end

