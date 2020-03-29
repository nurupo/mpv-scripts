#!/bin/sh

# MIT License
#
# Copyright (c) 2020 Maxim Biro <nurupo.contributions@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

set -eu

# mpv boss key script.
#
# Setup with your DE to be triggered on a keyboard shortcut.
#
# Assumes you have input-boss-key.lua bound on B.

if [ "$1" = "hide" ]; then
  WIDS="$(xdotool search --onlyvisible --name '.* - mpv$')"
  echo "$WIDS" > /tmp/mpv-boss-wids
  echo "$WIDS" | while read WID; do
    xdotool windowminimize $WID
    xdotool key --window $WID B
  done
elif [ "$1" = "show" ]; then
  if [ ! -f /tmp/mpv-boss-wids ]; then
    exit 1
  fi
  cat /tmp/mpv-boss-wids | while read WID; do
    xdotool key --window $WID B
    xdotool windowactivate $WID
  done
  rm /tmp/mpv-boss-wids
fi
