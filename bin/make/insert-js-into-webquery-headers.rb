#!/usr/bin/env ruby

require "fileutils"
require "command_runner"

module Calabash

  def self.write_header(header_file, constant_name, minified_js_file)
    self.log_banner("#{File.basename(header_file)}")

    header_lines = []

    match_found = false

    IO.read(header_file).force_encoding("utf-8").each_line do |line|
      if /#{constant_name}/.match(line)
        Calabash.log_debug("Found match for #{constant_name}.")
        match_found = true
        line.strip!
        new_js = IO.read(minified_js_file).force_encoding("utf-8").strip
        header_lines << %Q[static NSString *#{constant_name} = @"#{new_js}";]
      else
        header_lines << line
      end
    end

    if !match_found
      ["Could not find a match for #{constant_name} in",
       "",
       " #{header_file}",
       "",
       "Inserting #{File.basename(minified_js_file)} failed."].each do |line|
         Calabash.log_error(line)
       end
      exit 1
    end

    File.open(header_file, "w:UTF-8") do |f|
      f.puts(header_lines)
    end

    self.log_info("Injected #{File.basename(minified_js_file)} into #{constant_name}")
  end

  def self.debug?
    ENV["DEBUG"] == "1"
  end

  def self.log_debug(string)
    puts self.magenta("DEBUG: #{string}") if self.debug?
  end

  def self.log_info(string)
    puts self.green("INFO: #{string}")
  end

  def self.log_error(string)
    puts self.red("ERROR: #{string}")
  end

  def self.log_banner(string)
    puts self.magenta("\n### #{string} ###\n")
  end

  def self.log_unix_command(string)
    puts self.cyan("EXEC: #{string}")
  end

  def self.colorize(string, color)
		"\033[#{color}m#{string}\033[0m"
  end

  def self.red(string)
    colorize(string, 31)
  end

  def self.magenta(string)
    colorize(string, 35)
  end

  def self.green(string)
    colorize(string, 32)
  end

  def self.cyan(string)
    colorize(string, 36)
  end
end

MINIFY_BUILD_TIMEOUT = 10

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
    Calabash.log_error("Expected '#{build_js_script}' to exist")
    exit(1)
  end

  Calabash.log_banner("Minifying JavaScript")

  Calabash.log_unix_command(build_js_script)

  command_output = CommandRunner.run([build_js_script], timeout: MINIFY_BUILD_TIMEOUT)

  exit_code = command_output[:status].exitstatus

  out = command_output[:out]
  if Calabash.debug?
    puts out
  end

  if exit_code != 0
    Calabash.log_error("Expect build script to exit 0, but exited #{exit_code}")
    exit(exit_code)
  end

  if !File.exist?(mini_calabash_js)
    Calabash.log_error("Expected #{mini_calabash_js} to exist")
    exit(1)
  end

  if !File.exist?(mini_set_text_js)
    Calabash.log_error("Expected #{mini_set_text_js} to exist")
    exit(1)
  end

  Calabash.log_info("Created:")
  Calabash.log_info("  #{mini_calabash_js}")
  Calabash.log_info("  #{mini_set_text_js}")
end

Calabash.write_header(webquery_header, "LP_QUERY_JS", mini_calabash_js)
Calabash.write_header(settext_header, "LP_SET_TEXT_JS", mini_set_text_js)

