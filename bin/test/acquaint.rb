#!/usr/bin/env ruby

require "bundler"

Dir.chdir("cucumber") do
  Bundler.with_clean_env do
   args = ["exec", "cucumber",
           "-p", "simulator",
           "--tags", "@acquaint",
           "--format", "json", "-o", "reports/acquaint.json"]
   system("bundle", *args)

   system("./xtc-submit-acquaint.rb")
  end
end

