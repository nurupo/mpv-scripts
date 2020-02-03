-- MIT License
--
-- Copyright (c) 2020 Maxim Biro <nurupo.contributions@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- Allows copying YouTube and Twitch URLs with the current timestamp.
--
-- Useful when you want to share the exact moment of a video you are watching.
--
-- Works only for archive/VODs, doesn't work for live streams.

local cp = require('lib-copy-paste')
local wv = require('lib-web-video')

local function get_current_timestamp()
    local pos = mp.get_property_osd('time-pos')
    if not pos then
        mp.msg.error("Couldn't get video position")
        return nil
    end
    return pos:sub(1, 2) .. 'h' .. pos:sub(4, 5) .. 'm' .. pos:sub(7, 8) .. 's'
end

local function youtube_get_current_timestamp_url()
    local clean_url = wv.youtube_get_clean_url()
    if not clean_url then return nil end
    timestamp = get_current_timestamp()
    if not timestamp then return nil end
    if wv.youtube_is_live() then return nil end
    return clean_url .. '&t=' .. timestamp
end

local function twitch_get_current_timestamp_url()
    local clean_url = wv.twitch_get_clean_url()
    if not clean_url then return nil end
    timestamp = get_current_timestamp()
    if not timestamp then return nil end
    if wv.twitch_is_live() then return nil end
    return clean_url .. '?t=' .. timestamp
end

local function copy_timestamped_url()
    local timestamped_url
    if wv.is_youtube() then
        timestamped_url = youtube_get_current_timestamp_url()
    elseif wv.is_twitch() then
        timestamped_url = twitch_get_current_timestamp_url()
    end
    if not timestamped_url then
        mp.osd_message('Error: Failed to create timestamped URL.', 10)
        mp.msg.error('Failed to create timestamped URL.')
        return
    end
    cp.copy(timestamped_url, true)
end

mp.add_key_binding(nil, 'copy-timestamped-url',  copy_timestamped_url)
