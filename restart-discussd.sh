#!/bin/zsh

ps ax | grep 'node discussd' | grep -v grep | awk '{print $1}' | xargs kill
cd ~/discussd
node discussd.js -h 0.0.0.0 -p 8000 >|discussd.log 2>>|discussd.log &!
