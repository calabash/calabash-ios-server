#From https://github.com/moredip/Frank
#See LICENSE for licensing information

def discover_latest_sdk_version
  latest_iphone_sdk = `xcodebuild -showsdks | grep -o "iphoneos.*$"`.chomp
  version_part = latest_iphone_sdk[/iphoneos(.*)/,1]
  version_part
end

def build_dir
  File.expand_path 'build'
end

def build_cmd(arch)
  %Q[xcodebuild -scheme Framework -configuration Debug -sdk #{arch}#{discover_latest_sdk_version} BUILD_DIR=\"#{build_dir}\" GCC_PREPROCESSOR_DEFINITIONS="\\$(inherited) DEBUG=0" clean build]
end

desc "Build the arm library"
task :build_lib do
  sh build_cmd(:iphoneos)
end

task :copy_to_dist do
  sh "cp #{build_dir}/Debug-iphoneos/libCalabash.a dist/"
end

desc "clean build artifacts"
task :clean do
  rm_rf 'dist'
  rm_rf "#{build_dir}"
end

desc "create dist directory"
task :prep_dist do
  mkdir_p 'dist'
  mkdir_p "#{build_dir}"
end

task :build => [:clean, :prep_dist, :build_lib, :copy_to_dist]
task :default => :build
