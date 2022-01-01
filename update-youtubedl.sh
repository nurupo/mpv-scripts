#!/usr/bin/env bash

if [ ! -d ".pyenv" ]; then
  virtualenv -p /usr/bin/python3 .pyenv
fi

source .pyenv/bin/activate
.pyenv/bin/pip3 install -U youtube-dl
.pyenv/bin/pip3 install -U streamlink
.pyenv/bin/pip3 install -U yt-dlp
