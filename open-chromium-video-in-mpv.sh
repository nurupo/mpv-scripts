#!/bin/bash

# MIT License
#
# Copyright (c) 2018-2020 Maxim Biro <nurupo.contributions@gmail.com>
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

set -euo pipefail

# Opens a video playing in Chromium in mpv.
# Set to run in your DE on some hotkey and press it when on a video page.

# <window title to match> <URL to match> <mpv arguments>
config=(
' - YouTube - Chromium' 'https://www.youtube.com/watch' '--no-border --ontop --geometry 1280x720+313+148'
    'Twitch - Chromium' 'https://www.twitch.tv'         '--no-border --ontop --geometry 1340x754+240+198'
)

config_columns=3

echo_config_column()
{
  echo "${config[$(( $1 + ( $config_current_row - 1 ) * $config_columns ))]}"
}

copy_chromium_address()
{
  xdotool key alt+d
  xdotool key ctrl+c
}

active_window_title_matches()
{
  xdotool getactivewindow getwindowname | grep -q "$1"
}

config_current_row=1
while [ "$config_current_row" -le "$(( ${#config[@]} / $config_columns ))" ]; do
  if active_window_title_matches "$(echo_config_column 0)"; then
    copy_chromium_address
    if xclip -o | grep -q "$(echo_config_column 1)"; then
      mpv $(echo_config_column 2) "$(xclip -o)" &
      break
    fi
  fi
  config_current_row="$((config_current_row + 1))"
done
