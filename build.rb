#!/usr/bin/env ruby
# Possible flags are:
#   --release     build this module for final distribuition
#   --root DIR    install the binary into this directory. If this flag is not set - the script
#                 redeploys kext to local machine and restarts it

CWD = File.dirname(__FILE__)
BUNDLE_DIR = '/System/Library/Filesystems/fuse4x.fs'
Dir.chdir(CWD)

release = ARGV.include?('--release')
root_dir = ARGV.index('--root') ? ARGV[ARGV.index('--root') + 1] : nil

abort("root directory #{root_dir} does not exist") if ARGV.index('--root') and not File.exists?(root_dir)

system('git clean -xdf') if release

configuration = release ? 'Release' : 'Debug'
flags = '-configuration ' + configuration
if release then
  flags += ' MACOSX_DEPLOYMENT_TARGET=10.5'
else
  flags += ' ONLY_ACTIVE_ARCH=YES'
end

system("xcodebuild SYMROOT=build SHARED_PRECOMPS_DIR=build -PBXBuildsContinueAfterErrors=0 -parallelizeTargets -alltargets #{flags}") or abort("cannot build kext")

install_path = root_dir ? File.join(root_dir, BUNDLE_DIR) : BUNDLE_DIR
system("sudo mkdir -p #{install_path}")
system("sudo cp -R build/#{configuration}/fuse4x.fs.bundle/ #{install_path}")

launchd_dir = root_dir ? File.join(root_dir, '/System/Library/LaunchAgents') : '/System/Library/LaunchAgents'
system("sudo mkdir -p #{launchd_dir}")
system("sudo cp launchd.plist #{launchd_dir}/org.fuse4x.autoupdater.plist")
# Most of the files are created with XCode, autotools and have correct file mode.
# From other side some files are copied right from source tree. And the files have permissions
# depending on the user umask ('git checkout' does not change permissions).
# Set file mode manually to make it deterministic.
system("sudo chmod 644 #{launchd_dir}/org.fuse4x.autoupdater.plist")
