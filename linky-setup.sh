#!/bin/bash

set -e

if ! which northwatcher >/dev/null 2>/dev/null; then
  npm install -g northwatcher
fi

if ! which terminal-notifier >/dev/null 2>/dev/null; then
  brew install terminal-notifier
fi

machine_name=$(hostname -s)
mkdir -p $HOME/Dropbox/Apps/Linky/$machine_name/Archive

cp $HOME/Dropbox/Apps/Linky/net.samhuri.northwatcher.plist $HOME/Library/LaunchAgents

if [[ ! -e $HOME/.northwatcher ]]; then
  echo "+ Dropbox/Apps/Linky/$machine_name ruby /Users/sjs/bin/linky-notify" >$HOME/.northwatcher
fi

if [[ ! -e /var/log/northwatcher.log ]]; then
  echo "Enter your password to create /var/log/northwatcher.log."
  sudo touch /var/log/northwatcher.log
  sudo chown sjs:staff /var/log/northwatcher.log
fi

launchctl load $HOME/Library/LaunchAgents/net.samhuri.northwatcher.plist

echo "* Linky is set up!"
