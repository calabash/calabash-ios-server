#!/usr/bin/env ruby

require 'fileutils'

simulator = File.expand_path('./calabash-dylibs/libCalabashDynSim.dylib')
device = File.expand_path('./calabash-dylibs/libCalabashDyn.dylib')

framework = File.expand_path('./calabash.framework')

# run-loop
target_dir = File.expand_path('~/git/run_loop/spec/resources/dylibs')
if Dir.exist? target_dir
  puts "Installing to '#{target_dir}'"
  FileUtils.cp_r(simulator, target_dir)
  FileUtils.cp_r(device, target_dir)
else
  puts 'Skipping run-loop install'
end

# CalSmokeApp
target_dir = File.expand_path('~/git/cal-ios-smoke-test-app/CalSmokeApp')
if Dir.exist? target_dir
  puts "Installing to '#{target_dir}'"
  FileUtils.cp_r(simulator, target_dir)
  FileUtils.cp_r(device, target_dir)
  target_dir = File.join(target_dir, 'calabash.framework')
  FileUtils.rm_rf(target_dir)
  system('ditto', *[framework, target_dir])
else
  puts 'Skipping CalSmokeApp install'
end

# CalWebViewApp
target_dir = File.expand_path('~/git/cal-ios-webview-test-app/CalWebViewApp/')
if Dir.exist? target_dir
  puts "Installing to '#{target_dir}'"
  FileUtils.cp_r(simulator, target_dir)
  FileUtils.cp_r(device, target_dir)
  target_dir = File.join(target_dir, 'calabash.framework')
  FileUtils.rm_rf(target_dir)
  system('ditto', *[framework, target_dir])
else
  puts 'Skipping CallWebViewApp install'
end
