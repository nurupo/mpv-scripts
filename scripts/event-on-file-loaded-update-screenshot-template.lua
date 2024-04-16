-- MIT License
--
-- Copyright (c) 2020-2024 Maxim Biro <nurupo.contributions@gmail.com>
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
-- Only YouTube and Twitch videos are affected, sceenshots for everything else
-- will use the same format as before.
--
-- Illegal characters in filenames are replaced with the underscore '_'.

package.path = debug.getinfo(1).source:match("@?(.*/)") .. '?.lua;' .. package.path
local wv = require('lib-web-video')

local function sanitize_filename(filename)
    -- some symbols and sequences of characters have special meaning when used
    -- as a pattern and as such patterns must be escaped if we want them to be
    -- treated literally
    local function escape_pattern(text)
        return text:gsub("%W", "%%%1")
    end

    local function sanitize(filename, disallowed_characters)
        local disallowed_characters_pattern = '[' .. escape_pattern(disallowed_characters) .. ']'
        return filename:gsub(disallowed_characters_pattern, "_")
    end

    if package.config:sub(1,1) == '\\' then -- Windows
        -- https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
        return sanitize(filename, '<>:"/\\|?*')
    else -- *nix
        -- macOS used to disallow the colon ':', but sounds like it's allowed now
        return sanitize(filename, '/')
    end
end

local function get_url_screenshot_template()
    local function get_url_screenshot_template_()
        if wv.is_youtube() then
            if wv.youtube_is_live() then
                return '%F.%n'
            end
            local clean_url = wv.youtube_get_clean_url()
            if not clean_url then
                return nil
            end
            return clean_url:sub(clean_url:find("/[^/]*$") + 1) .. '&t=' .. '%wHh%wMm%wSs'
        elseif wv.is_twitch() then
            if wv.twitch_is_live() then
                return '%F.%n'
            end
            local clean_url = wv.twitch_get_clean_url()
            if not clean_url then
                return nil
            end
            return clean_url:sub(clean_url:find("/[^/]*$") + 1) .. '&t=' .. '%wHh%wMm%wSs'
        end
        return nil
    end

    local template = get_url_screenshot_template_()
    if not template then
        return nil
    end
    return sanitize_filename(template)
end

local original_screenshot_template = mp.get_property('screenshot-template')

local function update_screenshot_template()
    mp.set_property('screenshot-template', original_screenshot_template)
    local path = mp.get_property('path')
    if path:find('^https?://') then
        local screenshot_template = get_url_screenshot_template()
        if screenshot_template then
            mp.set_property('screenshot-template', screenshot_template)
        end
    end
    mp.msg.info('screenshot-template=' .. mp.get_property('screenshot-template'))
end

mp.register_event('file-loaded', update_screenshot_template)
