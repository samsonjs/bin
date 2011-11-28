#!/bin/bash

dir="$1"
if [[ -d "$1/.git" ]]; then
    cd "$1"
    git clean -fq
    git pull
else
    echo "error: $1 is not a git repo"
    exit 1
fi

