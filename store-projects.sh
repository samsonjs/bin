#!/bin/sh

rsync -ave ssh --delete "$HOME/Projects" nofxwiki.net:.
