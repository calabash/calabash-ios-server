#!/usr/bin/env ruby

unless `gem list run_loop -i`.chomp == 'true'
  install_gem('run_loop')
end

require 'run_loop'

unless `gem list retriable -i`.chomp == 'true'
  install_gem('retriable')
end

require 'retriable'

def log_cmd(msg)
  puts "\033[36mEXEC: #{msg}\033[0m" if msg
end

def log_pass(msg)
  puts "\033[32mPASS: #{msg}\033[0m" if msg
end

def log_fail(msg)
  puts "\033[31mFAIL: #{msg}\033[0m" if msg
end

def log_info(msg)
  puts "\033[35mINFO: #{msg}\033[0m" if msg
end

def do_system(cmd, opts={})
  default_opts = {:pass_msg => nil,
                  :fail_msg => nil,
                  :exit_on_nonzero_status => true,
                  :env_vars => {},
                  :log_cmd => true,
                  :obscure_fields => [],
                  :on_failure_proc => nil}
  merged_opts = default_opts.merge(opts)

  obscure_fields = merged_opts[:obscure_fields]

  if not obscure_fields.empty? and merged_opts[:log_cmd]
    obscured = cmd.split(' ').map do |token|
      if obscure_fields.include? token
        "#{token[0,1]}***#{token[token.length-1,1]}"
      else
        token
      end
    end
    log_cmd obscured.join(' ')
  elsif merged_opts[:log_cmd]
    log_cmd cmd
  end

  exit_on_err = merged_opts[:exit_on_nonzero_status]
  unless exit_on_err
    system 'set +e'
  end

  env_vars = merged_opts[:env_vars]
  res = system(env_vars, cmd)
  exit_code = $?.exitstatus

  if res
    log_pass merged_opts[:pass_msg]
  else
    log_fail merged_opts[:fail_msg]
    on_failure_proc = merged_opts[:on_failure_proc]
    on_failure_proc.call if on_failure_proc
    exit exit_code if exit_on_err
  end
  system 'set -e'
  exit_code
end

def travis_ci?
  ENV['TRAVIS']
end

def update_rubygems
  do_system('gem update --system',
            {:pass_msg => 'updated rubygems',
             :fail_msg => 'could not update rubygems'})
end

def uninstall_gem(gem_name)
  do_system("gem uninstall -Vax --force --no-abort-on-dependent #{gem_name}",
            {:pass_msg => "uninstalled '#{gem_name}'",
             :fail_msg => "could not uninstall '#{gem_name}'"})
end

def install_gem(gem_name, opts={})
  default_opts = {:prerelease => false,
                  :no_document => true}
  merged_opts = default_opts.merge(opts)

  pre = merged_opts[:prerelease] ? '--pre' : ''
  no_document = merged_opts[:no_document] ? '--no-document' : ''

  do_system("gem install #{no_document} #{gem_name} #{pre}",
            {:pass_msg => 'install calabash-cucumber',
             :fail_msg => 'could not install calabash-cucumber'})
end

# return a +Hash+ of XTC device sets where the key is some arbitrary description
# and the value is a <tt>XTC device set</tt>
def read_device_sets(path='~/.xamarin/test-cloud/ios-sets.csv')
  ht = Hash.new
  begin
    File.read(File.expand_path(path)).split("\n").each do |line|
      unless line[0].eql?('#')
        tokens = line.split(',')
        if tokens.count == 2
          ht[tokens[0].strip] = tokens[1].strip
        end
      end
    end
    ht
  rescue Exception => _
    log_fail 'cannot read device set information'
    return nil
  end
end

def read_api_token(account_name)
  path = File.expand_path("~/.xamarin/test-cloud/#{account_name}")

  unless File.exist?(path)
    log_fail "cannot read account information for '#{account_name}'"
    log_fail "file '#{path}' does not exist"
    return nil
  end

  begin
    IO.readlines(path).first.strip
  rescue Exception => e
    log_fail "cannot read account information for '#{account_name}'"
    log_fail e
    return nil
  end
end

def alt_xcode_install_paths
  @alt_xcode_install_paths ||= lambda {
    min_xcode_version = RunLoop::Version.new('5.1')
    Dir.glob('/Xcode/*/*.app/Contents/Developer').map do |path|
      xcode_version = path[/(\d\.\d(\.\d)?)/, 0]
      if RunLoop::Version.new(xcode_version) >= min_xcode_version
        path
      else
        nil
      end
    end
  }.call.compact
end

def xcode_select_xcode_hash
  @xcode_select_xcode_hash ||= lambda {
    ENV.delete('DEVELOPER_DIR')
    xcode_tools = RunLoop::XCTools.new
    {:path => xcode_tools.xcode_developer_dir,
     :version => xcode_tools.xcode_version}
  }.call
end

def alt_xcode_details_hash(skip_versions = [RunLoop::Version.new('6.0'), RunLoop::Version.new('6.0.1')])
  @alt_xcodes_gte_xc511_hash ||= lambda {
    ENV.delete('DEVELOPER_DIR')
    xcode_select_path = RunLoop::XCTools.new.xcode_developer_dir
    paths =  alt_xcode_install_paths
    paths.map do |path|
      begin
        ENV['DEVELOPER_DIR'] = path
        version = RunLoop::XCTools.new.xcode_version
        if path == xcode_select_path
          nil
        elsif skip_versions.include?(version)
          nil
        elsif version >= RunLoop::Version.new('5.1.1')
          {
                :version => RunLoop::XCTools.new.xcode_version,
                :path => path
          }
        else
          nil
        end
      ensure
        ENV.delete('DEVELOPER_DIR')
      end
    end
  }.call.compact
end
