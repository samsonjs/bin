#!/bin/sh

rsync -ave ssh --delete nofxwiki.net:Projects "$HOME/"
