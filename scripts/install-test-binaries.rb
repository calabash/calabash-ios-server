#!/usr/bin/env ruby

require 'fileutils'

simulator = File.expand_path('./calabash-dylibs/libCalabashDynSim.dylib')
device = File.expand_path('./calabash-dylibs/libCalabashDyn.dylib')

# run-loop
rspec_resources_dir = File.expand_path('~/git/run_loop/spec/resources/dylibs')
FileUtils.cp_r(simulator, rspec_resources_dir)
FileUtils.cp_r(device, rspec_resources_dir)
