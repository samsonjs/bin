#!/bin/bash

if [[ -d ~/Projects/web/samhuri.net ]]; then
	cd ~/Projects/web/samhuri.net
elif [[ -d ~/samhuri.net ]]; then
	cd ~/samhuri.net
else
	echo "error: samhuri.net directory not found"
	exit 1
fi

cd _blog
git clean -fq
git pull
cd ..

git clean -fq
git pull

make publish
