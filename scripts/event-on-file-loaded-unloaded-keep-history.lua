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

-- Logs which files where opened and closed and when.

local path
local title

local function pad(str, len, char)
  if char == nil then char = ' ' end
  return str .. string.rep(char, len - #str)
end

local function log(event)
  local f = io.open(os.getenv('HOME') .. '/.config/mpv/history.log', 'a+')
  f:write(('[%s] %s %s %s\n'):format(os.date('%Y-%m-%d %H:%M:%S'), pad(event, 12), pad(path, 56), title))
  f:close()
end

local function log_file_loaded(event)
  path = mp.get_property('path')
  title = mp.get_property_osd('media-title')
  log('loaded')
end

local function log_end_file(event)
  log('unloaded')
end  

mp.register_event('file-loaded', log_file_loaded)
mp.register_event('end-file', log_end_file)

