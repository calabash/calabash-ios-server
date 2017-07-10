#!/usr/bin/env ruby

require "bundler"

Dir.chdir("cucumber") do
  Bundler.with_clean_env do

    require "run_loop"
    RunLoop::CoreSimulator.quit_simulator

    args = ["exec", "cucumber",
            "-p", "simulator",
            "--tags", "@acquaint",
            "--format", "json", "-o", "reports/acquaint.json"]
    system("bundle", *args)

    system("./xtc-submit-acquaint.rb")
  end
end

