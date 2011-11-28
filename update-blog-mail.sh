#!/bin/bash

if [[ -d /home/sjs/blog-mail ]]; then
    cd /home/sjs/blog-mail
    git clean -fq
    git pull
fi

