#!/bin/sh

# The kext might not be loaded yet, so silently ignore the output
kextunload -b org.fuse4x.kext.fuse4x 2> /dev/null

rm -r /Library/Frameworks/Fuse4X.framework/
rm -r /System/Library/Filesystems/fuse4x.fs/
rm /System/Library/LaunchAgents/org.fuse4x.autoupdater.plist
rm ~/Library/Preferences/org.fuse4x.autoupdater.plist
rm ~root/Library/Preferences/org.fuse4x.autoupdater.plist
rm -r /System/Library/Extensions/fuse4x.kext/
rm /usr/local/bin/sshfs
rm /usr/local/share/man/man1/sshfs.1
rm -r /usr/local/include/fuse*
rm /usr/local/lib/libfuse4x.*
rm /usr/local/lib/pkgconfig/fuse.pc
