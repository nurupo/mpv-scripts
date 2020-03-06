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

-- Changes the screenshot template to include YouTube and Twitch URL formatted
-- timestamp, e.g. watch?v=9bZkp7q19f0&t=00h01m09s.png
--
-- Doesn't work for ongoing live streams, only for archives/VODs. Sets the
-- screenshot template for live streams to '%F.%n' instead, as youtube-dl can't
-- tell us the current video position in a live stream.
--
-- Only YouTube and Twitch videos are affected, sceenshots for evrythng else
-- will use the same format as before.

package.path = os.getenv('HOME') .. '/.config/mpv/scripts/?.lua;' .. package.path
local wv = require('lib-web-video')

local function get_url_screenshot_template()
    if wv.is_youtube() then
        if wv.youtube_is_live() then
            return '%F.%n'
        end
        local clean_url = wv.youtube_get_clean_url()
        if not clean_url then return nil end
        return clean_url:sub(clean_url:find("/[^/]*$") + 1) .. '&t=' .. '%wHh%wMm%wSs'
    elseif wv.is_twitch() then
        if wv.twitch_is_live() then
            return '%F.%n'
        end
        local clean_url = wv.twitch_get_clean_url()
        if not clean_url then return nil end
        return clean_url:sub(clean_url:find("/[^/]*$") + 1) .. '?t=' .. '%wHh%wMm%wSs'
    end
    return nil
end

local original_screenshot_template = mp.get_property('screenshot-template')

local function update_screenshot_template()
    mp.set_property('screenshot-template', original_screenshot_template)
    local path = mp.get_property('path')
    if path:find('^http?') then
        local screenshot_template = get_url_screenshot_template()
        if screenshot_template then
            mp.set_property('screenshot-template', screenshot_template)
        end
    end
    mp.msg.info('screenshot-template=' .. mp.get_property('screenshot-template'))
end

mp.register_event('file-loaded', update_screenshot_template)
