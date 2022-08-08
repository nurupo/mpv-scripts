-- MIT License
--
-- Copyright (c) 2020-2022 Maxim Biro <nurupo.contributions@gmail.com>
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

-- Allows copying and pasting of the currently playing file path.
--
-- Useful when you want to share a YouTube URL of a video you are watching, or
-- you want to open an URL in mpv that you have copied from somewhere else.
--
-- Hardcoded to recognize http(s) and file://. Anything that is not http(s) or
-- file:// is treated as a local file path.

package.path = debug.getinfo(1).source:match("@?(.*/)") .. '?.lua;' .. package.path
local cp = require('lib-copy-paste')

local function copy_path()
    cp.copy(mp.get_property('path'), true)
end

local function file_exists(name)
   local f = io.open(name, "r")
   if f then
       f:close()
       return true
   else
       return false
   end
end

local function paste_path()
    local path = cp.paste(true)
    if not path then return end
    if path:find('^file://') then
        path = path:sub(8)
    end
    -- make sure the file exists or it's an http(s) URL, as mpv terminates on things it can't open
    if not file_exists(path) and not path:find('^http?') then
        mp.osd_message('Error: File "' .. path .. '" doesn\'t exist!', 10)
        mp.msg.error('File "' .. path .. '" doesn\'t exist!')
        return
    end
    mp.commandv('loadfile', path)
end

mp.add_key_binding(nil, 'copy-paste-path-copy',  copy_path)
mp.add_key_binding(nil, 'copy-paste-path-paste', paste_path)
