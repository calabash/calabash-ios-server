#!/usr/bin/env ruby

require 'fileutils'
require "luffa"

this_dir = File.dirname(__FILE__)
calabash_js_dir = File.expand_path(File.join(this_dir, '..', '..', 'calabash-js'))
minified_js = File.join(calabash_js_dir, "build", "calabash-min.js")
header = File.expand_path(File.join(".", "calabash", "Classes", "WebViewQuery", "LPWebQuery.h"))

Dir.chdir(calabash_js_dir) do
  build_js_script = File.expand_path('./build.sh')
  unless File.exist?(build_js_script)
    Luffa.log_fail("FAIL: expected '#{build_js_script}' to exist")
    exit 1
  end

  options = {
    :pass_msg => "Built #{minified_js}",
    :fail_msg => "Could not build #{minified_js}"
  }

  exit_code = Luffa.unix_command(build_js_script, options)

  if exit_code != 0
    exit(exit_code)
  end

  if !File.exist?(minified_js)
    Luffa.log_fail("Expected #{minified_js} to exist")
  end
end

new_lines = []

IO.read(header).force_encoding("utf-8").each_line do |line|
  if /LP_QUERY_JS/.match(line)
    line = line.strip
    new_js = IO.read(minified_js).force_encoding("utf-8").strip
    new_lines << %Q[static NSString *LP_QUERY_JS = @"#{new_js}";]
  else
    new_lines << line
  end
end

File.open(header, "w:UTF-8") do |f|
  f.puts(new_lines)
end

puts "Done."

