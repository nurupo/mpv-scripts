-- MIT License
--
-- Copyright (c) 2024 Maxim Biro <nurupo.contributions@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the 'Software'), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- Copies the persistent URL of the media -- either its path if it's http(s),
-- or the PURL metadata, if present (e.g. from ytdl audio/video).
--
-- Basically, I sometimes download videos via ytdl, separately from mpv, and
-- want to be able to easily get their URLs.

package.path = debug.getinfo(1).source:match('@?(.*/)') .. '?.lua;' .. package.path
local cp = require('lib-copy-paste')

local function is_url(str)
    return string.match(str, '^https?://')
end

local function copy_purl()
    local path = mp.get_property('path')
    if is_url(path) then
        cp.copy(path, true)
        return
    end
    local purl = mp.get_property('metadata/by-key/PURL')
    if purl then
        cp.copy(purl, true)
        return
    end
    mp.osd_message('Error: No persistent URL found.')
end

mp.add_key_binding(nil, 'copy-purl',  copy_purl)
