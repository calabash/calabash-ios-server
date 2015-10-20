#!/usr/bin/env ruby
require 'fileutils'
require 'open3'

require File.expand_path(File.join(File.dirname(__FILE__), 'test-helpers'))

this_dir = File.dirname(__FILE__)
calabash_js_dir = File.expand_path(File.join(this_dir, '..', 'calabash-js'))

Dir.chdir(calabash_js_dir) do
  build_js_script = File.expand_path('./build.sh')
  unless File.exist?(build_js_script)
    puts "FAIL: expected '#{build_js_script}' to exist"
    exit 1
  end

  options =
        {
              :pass_msg => 'Injected calabash-js into web view headers',
              :fail_msg => 'Could not inject calabash-js into web view headers'
        }

  exit_code = do_system(build_js_script, options)
  exit(exit_code)
end


# unless system("./build.sh")
#   puts "Failed build.sh"
#   exit(false)
# end
#
# new_lines = []
# lp_web_query = "CalabashJS/CalabashJSLib/LPWebQuery.h"
# IO.read(File.expand_path(lp_web_query)).each_line do |line|
#   if /LP_QUERY_JS/.match(line)
#     puts "Found #{line}"
#     line = line.strip
#     new_js = IO.read('build/calabash-min.js').strip
#     new_lines << %Q[static NSString *LP_QUERY_JS = @"#{new_js}";]
#   else
#     new_lines << line
#   end
# end
# File.open(lp_web_query,'w') do |f|
#   f.puts(new_lines)
# end
