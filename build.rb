#!/usr/bin/env ruby
# Possible flags are:
#   --debug       this builds distribuition with debug flags enabled
#   --root DIR    install the binary into this directory. If this flag is not set - the script
#                 redeploys kext to local machine and restarts it

CWD = File.dirname(__FILE__)
BUNDLE_DIR = '/System/Library/Filesystems/fuse4x.fs'
Dir.chdir(CWD)

debug = ARGV.include?('--debug')
root_dir = ARGV.index('--root') ? ARGV[ARGV.index('--root') + 1] : nil

abort("root directory #{root_dir} does not exist") if ARGV.index('--root') and not File.exists?(root_dir)

configuration = debug ? 'Debug' : 'Release'

system("xcodebuild -parallelizeTargets -configuration #{configuration} -alltargets") or abort("cannot build kext")

install_path = root_dir ? File.join(root_dir, BUNDLE_DIR) : BUNDLE_DIR
system("sudo mkdir -p #{install_path}")
system("sudo cp -R build/#{configuration}/fuse4x.fs.bundle/ #{install_path}")

launchd_dir = root_dir ? File.join(root_dir, '/System/Library/LaunchAgents') : '/System/Library/LaunchAgents'
system("sudo mkdir -p #{launchd_dir}")
system("sudo cp launchd.plist #{launchd_dir}/org.fuse4x.autoupdater.plist")
