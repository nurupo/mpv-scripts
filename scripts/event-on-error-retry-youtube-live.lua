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

-- Keeps trying to open an upcoming YouTube live stream until it starts
--
-- Requires curl to be installed (surprisingly, at some point Windows 10 started including curl)

package.path = debug.getinfo(1).source:match("@?(.*/)") .. '?.lua;' .. package.path
local wv  = require 'lib-web-video'
local msg = require 'mp.msg'

local youtube_id
local path
local original_idle
local overrode_idle = false

local function record_youtube_id()
    youtube_id = nil
    path = nil
    if wv.is_youtube() then
        youtube_id = wv.youtube_get_id()
        path = mp.get_property('path')
        original_idle = mp.get_property('idle')
        if not overrode_idle then
            msg.verbose("Temporarily setting idle=yes as it's required for the script to work.")
            mp.set_property('idle', 'yes')
            overrode_idle = true
        end
    end
end

local function restore_idle()
    if overrode_idle then
        msg.verbose("Restoring idle=" .. original_idle)
        mp.set_property('idle', original_idle)
        overrode_idle = false
    end
end

local function http_code(url)
    local null_device = mp.get_property_native("platform") == "windows" and "NUL" or "/dev/null"
    local result = mp.command_native({
        name = "subprocess",
        playback_only = false,
        args = {"curl", "-s", "-o", null_device, "-w", "%{http_code}", "--", url},
        capture_stdout = true,
        capture_stderr = true,
    })
    if not result or result.status ~= 0 then
        msg.warn("Failed to get the HTTP code of " .. url)
        if result then
            msg.warn('status: ' .. result.status)
            msg.warn('stdout: ' .. result.stdout)
            msg.warn('stderr: ' .. result.stderr)
        end
        return nil
    end
    return result.stdout
end

local function youtube_has_live_thumbnail(id)
    return http_code('https://i.ytimg.com/vi/' .. id .. '/default_live.jpg') == '200'
end

local function retry_youtube_live(event)
    if event.reason ~= "error" then
        return
    end
    if youtube_id and youtube_has_live_thumbnail(youtube_id) then
        msg.info("This appears to be an upcoming YouTube live stream. Will keep retying to open it until it goes live.")
        mp.add_timeout(8.5, function()
            mp.commandv('loadfile', path)
        end)
    end
end

mp.register_event('end-file', retry_youtube_live)
mp.register_event('start-file', record_youtube_id)
mp.register_event('file-loaded', restore_idle)
