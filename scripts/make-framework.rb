#!/usr/bin/ruby
require 'fileutils'

# to be run after +make+
# 1. combines the Debug-iphoneos and Debug-iphonesimulator libs into a FAT lib
# 2. creates a static Framework using the combined lib
# 3. stages the calabash.framework to ./

# @return [String] the combined binary name
def combined_lib_name
  'calabash-combined.a'
end

# @return [String] constructs a path using +directory+ and +lib_name+
# @param [String] directory the directory path
# @param [String] lib_name name of the library
# @raise [RuntimeError] if no file exists at path
def path_to_lib(directory, lib_name)
  unless File.directory?(directory)
    raise "expected directory '#{directory}' to exist"
  end

  path = File.join(directory, lib_name)

  unless File.exists?(path)
    raise "expected library at '#{path}' to exist"
  end
  path
end

# @return [String] the path to the device lib
# @param [Hash] opts directory and lib name options
def path_to_device_lib(opts = {})
  default_opts = {:directory => './build/Debug-iphoneos',
                  :lib_name => 'libcalabash-device.a'}
  merged = default_opts.merge(opts)
  path_to_lib(merged[:directory], merged[:lib_name])
end

# @return [String] the path to the simulator lib
# @param [Hash] opts directory and lib name options
def path_to_simulator_lib(opts = {})
  default_opts = {:directory => './build/Debug-iphonesimulator',
                  :lib_name => 'libcalabash-simulator.a'}
  merged = default_opts.merge(opts)

  path_to_lib(merged[:directory], merged[:lib_name])
end

# creates a staging directory for the combined library.
#
# if a directory exists at the :directory option it is deleted.
#
# @return [String] path to the staging directory
# @param [Hash] opts directory option
def make_combined_lib_staging_dir(opts = {})
  default_opts = {:directory => './build/Debug-combined'}
  merged = default_opts.merge(opts)
  path = merged[:directory]
  if File.exists?(path)
    FileUtils.rm_r(path)
  end
  FileUtils.mkdir(path)
  path
end

# @return [String] a file path to use as the -output of lipo -create
# @param [String] directory the base directory
# @param [String] name the name of the combined lib
def combined_lib_path(directory, name)
  unless File.directory?(directory)
    raise "expected directory '#{directory}' to exist"
  end
  File.join(directory, name)
end

# @param [Array<String>] inputs an array of lib paths to pass to lipo
# @param [Object] output the combined library
# @return [String] lipo create command
def lipo_cmd(inputs, output)
  "xcrun lipo -create #{inputs.join(' ')} -output #{output}"
end

# @return [String] lipo info command
# @param [String] lib path to a library or executable binary
def lipo_info(lib)
  "xcrun lipo -info #{lib}"
end


def lipo_put_info(lib)
  cmd = lipo_info(lib)
  puts 'INFO: checking combined lib'
  puts "INFO: #{cmd}"
  lipo_info = `#{cmd}`
  result = $?

  unless result.success?
    puts 'FAIL: could not check the combined lib'
    puts "FAIL: '#{lipo_info.strip}'"
    exit result.to_i
  end
end

def lipo_verify(lib, arch, sdk)
  "xcrun -sdk #{sdk} lipo #{lib} -verify_arch '#{arch}'"
end

def lipo_verify_arches(lib, arches=['i386', 'x86_64', 'armv7', 'armv7s', 'arm64'])
  arches.each do |arch|
    sdk = /i386|x86_64/.match(arch) ? 'iphonesimulator' : 'iphoneos'
    cmd = lipo_verify(lib, arch, sdk)
    lipo_verify = `#{cmd}`
    result = $?
    if result.success?
      puts "INFO: #{lib} contains arch '#{arch}'"
    else
      if lipo_verify != nil and lipo_verify != ''
        puts "FAIL: could not verify lib contains arch '#{arch}'"
        puts "FAIL: '#{lipo_verify}'"
        exit result.to_i
      else
        puts "FAIL: lib '#{lib}' does not contain arch '#{arch}'"
        exit result.to_i
      end
    end
  end

end

def lipo_combine_libs
  staging = make_combined_lib_staging_dir
  inputs = [path_to_device_lib, path_to_simulator_lib]
  output = combined_lib_path(staging, combined_lib_name)
  cmd = lipo_cmd(inputs, output)

  puts 'INFO: combining libs'
  puts "INFO: #{cmd}"
  lipo_create = `#{cmd}`
  result = $?

  unless result.success?
    puts 'FAIL: could not create combined lib'
    puts "FAIL: '#{lipo_create.strip}'"
    exit result.to_i
  end

  lipo_put_info(output)
  lipo_verify_arches(output)
end


def framework_product_name
  'calabash'
end

def make_framework(opts = {})
  default_opts = {:directory => './build/Debug-combined/calabash.framework',
                  :combined_lib => combined_lib_name,
                  :version_exe => './build/Debug/version'}

  merged = default_opts.merge(opts)

  directory = merged[:directory]
  if File.exists?(directory)
    FileUtils.rm_r(directory)
  end

  puts "INFO: making framework at '#{directory}'"

  framework_name = framework_product_name

  FileUtils.mkdir_p(File.join(directory, 'Versions/A/Headers'))

  combined_lib = merged[:combined_lib]
  puts "INFO: installing combined lib '#{combined_lib}' in '#{directory}'"

  Dir.chdir(directory) do
    `ln -sfh A Versions/Current`

    lib = "../#{combined_lib}"
    unless File.exists?(lib)
      puts 'FAIL: combined lib does not exist'
      puts "FAIL: could not find '#{File.join(Dir.pwd, lib)}'"
      exit 1
    end

    FileUtils.cp(lib, "./Versions/A/#{framework_name}")
    `ln -sfh Versions/Current/#{framework_name} #{framework_name}`

    `ln -sfh Versions/Current/Headers Headers`

    `cp -a ../../Debug-iphoneos/calabashHeaders/* Versions/A/Headers`
  end


  version_exe = merged[:version_exe]
  puts "INFO: installing Resources to '#{directory}'"
  resource_path = File.join(directory, 'Versions/A/Resources')
  FileUtils.mkdir_p(resource_path)
  FileUtils.cp(version_exe, resource_path)

  Dir.chdir(directory) do
    `ln -sfh Versions/Current/Resources Resources`

    version = `Resources/version`.chomp!
    `ln -sfh A Versions/#{version}`
  end

  puts 'INFO: verifying framework'
  lib = "#{directory}/#{framework_name}"
  lipo_verify_arches(lib)
end

def stage_framework(opts = {})
  default_opts = {:source => './build/Debug-combined/calabash.framework',
                  :target => './'}
  merged = default_opts.merge(opts)

  source = merged[:source]
  target = merged[:target]
  puts "INFO: staging '#{source}' to '#{target}'"

  if File.directory?('./calabash.framework')
    puts 'INFO: removing old calabash.framework'
    FileUtils.rm_r('./calabash.framework')
  end

  tar_file = './calabash.framework.tar'
  if File.exists?(tar_file)
    puts 'INFO: removing old calabash.framework.tar'
    FileUtils.rm(tar_file)
  end

  puts "INFO: making a tarball of #{source}"
  `tar -C #{File.join(source, '..')} -cf calabash.framework.tar calabash.framework`

  puts 'INFO: extracting calabash.framework from tarball'
  `tar -xf #{tar_file}`
  puts 'INFO: cleaning up'
  FileUtils.rm(tar_file)

end

if ARGV[0] == 'verify'
  lipo_combine_libs
  make_framework
  stage_framework
  exit 0
end


## Test
## $ ruby make-framework.rb
## $ make-framework.rb
if __FILE__ == $0
  require 'test/unit'
  require 'fileutils'


  class LocalTest < Test::Unit::TestCase

    def test_product_name
      assert_equal(combined_lib_name, 'calabash-combined.a')
    end

    def test_path_to_lib_dir_does_not_exist
      assert_raise RuntimeError do
        path_to_lib('tmp', nil)
      end
    end

    def test_path_to_lib_file_does_not_exist
      assert_raise RuntimeError do
        path_to_lib('test/build/Debug-iphonesimulator', 'bananas')
      end
    end

    def test_path_to_sim_returns_lib_path
      path = path_to_simulator_lib({:directory => 'test/build/Debug-iphonesimulator'})
      assert(File.exists?(path))
    end

    def test_path_to_device_returns_lib_path
      path = path_to_device_lib({:directory => 'test/build/Debug-iphoneos'})
      assert(File.exists?(path))
    end

    def test_create_staging_dir
      path = make_combined_lib_staging_dir({:directory => 'test/build/Debug-combined'})
      begin
        assert(File.directory?(path))
      rescue Exception => e
        raise e
      ensure
        if File.exist?(path)
          FileUtils.rm_r(path)
        end
      end
    end

    def test_product_path_no_dir
      assert_raise RuntimeError do
        combined_lib_path('tmp', nil)
      end
    end

    def test_product_path
      path = combined_lib_path('./test', 'foo.a')
      assert_equal(File.join('./test', 'foo.a'), path)
    end

    def test_lipo_cmd
      inputs = ['one-lib.a', 'two-lib.a']
      cmd = lipo_cmd(inputs, 'combined.lib')
      expected = 'lipo -create one-lib.a two-lib.a -output combined.lib'
      assert_equal(expected, cmd)
    end

  end
end
