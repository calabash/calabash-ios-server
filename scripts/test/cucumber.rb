#!/usr/bin/env ruby
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

Dir.chdir working_dir do

  do_system('make clean')
  do_system('make dylib_sim')
  do_system('make test_app')

end

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'cucumber'))

Dir.chdir working_dir do

  ensure_proc = Proc.new do
    do_system('mv Gemfile.backup Gemfile')
  end

  opts = {
        :on_failure_proc => ensure_proc
  }

  do_system('rm -rf .bundle')
  do_system('mkdir .bundle')
  do_system('touch .bundle/config')
  do_system('rm Gemfile.lock')

  do_system('mv Gemfile Gemfile.backup')
  do_system('cp Gemfile.develop Gemfile', opts)
  do_system('bundle update', opts)

  do_system('bundle exec cucumber', opts)

  ensure_proc.call

end
