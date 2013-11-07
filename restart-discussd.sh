#!/bin/zsh

ps ax | grep 'node discussd' | grep -v grep | cut -f1 -d' ' | xargs kill
cd ~/discussd
node discussd.js -h 0.0.0.0 -p 8000 >|discussd.log 2>>|discussd.log &!
