#!/usr/bin/env ruby

require 'open3'

if ARGV.count != 1
  lines = ['Usage: expect-no-offending-symbols.rb < symbol >',
           'Example:',
           'expect-no-offending-symbols.rb kSecAttrSynchronizable']
  raise(ArgumentError, lines.join("\n"))
end

symbol = ARGV[0]

cmd = "nm calabash.framework/calabash | sort | grep \"#{symbol}\""
puts "\033[36mEXEC: #{cmd}\033[0m"

Open3.popen3(cmd) do  |_, stdout,  stderr, _|
  out = stdout.read.strip
  err = stderr.read.strip
  if err != ''
    lines = ['Expected command:',
             cmd,
             'to generate no error output but found:',
             err]
    raise lines.join("\n")
  end
  if out != ''
    lines = ["Expected no symbol: '#{symbol}' in calabash.framework/calabash",
             'Found:',
             out]
    raise lines.join("\n")
  end
end

puts "\033[32mPASS: Did not find symbol '#{symbol}' in frameowork\033[0m"

exit 0
