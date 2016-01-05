#!/usr/bin/env ruby

require 'fileutils'
require "luffa"

module Calabash

  def self.write_header(header_file, constant_name, minified_js_file)
    header_lines = []

    IO.read(header_file).force_encoding("utf-8").each_line do |line|
      if /#{constant_name}/.match(line)
        puts "Found match for #{constant_name}"
        line.strip!
        new_js = IO.read(minified_js_file).force_encoding("utf-8").strip
        header_lines << %Q[static NSString *#{constant_name} = @"#{new_js}";]
      else
        header_lines << line
      end
    end

    File.open(header_file, "w:UTF-8") do |f|
      f.puts(header_lines)
    end
  end
end

this_dir = File.dirname(__FILE__)

calabash_js_dir = File.expand_path(File.join(this_dir, '..', '..', 'calabash-js'))
mini_calabash_js = File.join(calabash_js_dir, "build", "calabash-min.js")
mini_set_text_js = File.join(calabash_js_dir, "build", "set_text-min.js")

classes_dir = File.expand_path(File.join(".", "calabash", "Classes"))
webquery_header = File.expand_path(File.join(classes_dir, "WebViewQuery", "LPWebQuery.h"))
settext_header = File.expand_path(File.join(classes_dir, "FranklyServer", "Operations", "LPSetTextOperation.h"))

Dir.chdir(calabash_js_dir) do
  build_js_script = File.expand_path('./build.sh')
  unless File.exist?(build_js_script)
    Luffa.log_fail("FAIL: expected '#{build_js_script}' to exist")
    exit 1
  end

  options = {
    :pass_msg => "Built minified JavaScript for Calabash iOS headers",
    :fail_msg => "Could not build minified JavaScript for Calabash iOS headers"
  }

  exit_code = Luffa.unix_command(build_js_script, options)

  if exit_code != 0
    exit(exit_code)
  end

  if !File.exist?(mini_calabash_js)
    Luffa.log_fail("Expected #{mini_calabash_js} to exist")
  end

  if !File.exist?(mini_set_text_js)
    Luffa.log_fail("Expected #{mini_set_text_js} to exist")
  end
end

Calabash.write_header(webquery_header, "LP_QUERY_JS", mini_calabash_js)
Calabash.write_header(settext_header, "LP_SET_TEXT_JS", mini_set_text_js)

