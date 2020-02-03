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

-- Module for some common YouTube and Twitch stuff.

require 'mp.msg'

local wv = {}

function wv.youtube_get_id()
    local id
    local url = mp.get_property('path')
    id = url:match('https?://.*youtube.com/watch.*[&?]v=([^&=?]+)')
    if id then return id end
    id = url:match('https?://.*youtu.be/([^&=?]+)')
    if id then return id end
    mp.msg.error("Couldn't get YouTube video id from: " .. url)
    return nil
end

function wv.is_youtube()
    return wv.youtube_get_id() ~= nil
end

function wv.youtube_is_live()
    return mp.get_property('file-format') == 'hls'
end

function wv.youtube_get_clean_url()
    local id = wv.youtube_get_id()
    if not id then return nil end
    return 'https://www.youtube.com/watch?v=' .. id
end

function wv.twitch_get_id()
    local id
    local url = mp.get_property('path')
    id = url:match('https?://.*twitch.tv/videos/(%d+)')
    if not id then
        mp.msg.error("Couldn't get Twitch video id from: " .. url)
        return nil
    end
    return id
end

function wv.is_twitch()
    local url = mp.get_property('path')
    return url:match('https?://.*twitch.tv/.+') ~= nil
end

function wv.twitch_is_live()
    local url = mp.get_property('path')
    return url:match('https?://.*twitch.tv/videos/') == nil and
           mp.get_property('file-format') == 'hls'
end

function wv.twitch_get_clean_url()
    local id = wv.twitch_get_id()
    if not id then return nil end
    return 'https://www.twitch.tv/videos/' .. id
end

return wv
