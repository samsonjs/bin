#!/bin/sh

echo "* Save screenshtots to ~/Dropbox/Pictures/screenshots"
defaults write com.apple.screencapture location ~/Dropbox/Pictures/screenshots

echo "* Disable shadows on screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

echo "* Set screenshot name to \"screenshot\""
defaults write com.apple.screencapture name screenshot

echo "* Show build duration in Xcode"
defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

echo "* Enable text selection in QuickLook"
defaults write com.apple.finder QLEnableTextSelection -bool YES
