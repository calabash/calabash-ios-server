#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

def test_make_rules(env_vars, xcode_version)
  install_gem('xcpretty')
  do_system('make clean', {:env_vars => env_vars})
  do_system('make framework', {:env_vars => env_vars})
  do_system('make frank', {:env_vars => env_vars})

  # Requires injecting xcspec files into Xcode.app bundle for Xcode < 6.0
  if xcode_version >= RunLoop::Version.new('6.0')
    do_system('make dylibs', {:env_vars => env_vars})
    do_system('make dylib_sim', {:env_vars => env_vars})
    do_system('make all', {:env_vars => env_vars})
  end

  do_system('make webquery_headers')
end

Dir.chdir working_dir do
  xcode_details = xcode_select_xcode_hash
  log_info "Testing make rules #{xcode_details[:path]}"
  env_vars = {}
  test_make_rules(env_vars, xcode_details[:version])

  alt_xcode_details_hash.each do |details|
    log_info "Regression: testing make rules #{details[:path]}"
    # noinspection RubyStringKeysInHashInspection
    env_vars =
          {
                'DEVELOPER_DIR' => details[:path]
          }
    test_make_rules(env_vars, details[:version])
  end
end
