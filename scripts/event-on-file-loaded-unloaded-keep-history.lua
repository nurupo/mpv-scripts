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

-- Logs which files where opened and closed and when.
--
-- The log is stored as "../history.log" relative to this script.
--
-- Log format: [<date-time>] loaded|unloaded <path> <title>
--
-- Uses tabs as column separators, padding columns with spaces to the right in
-- an attempt to make the files more readable when opened as a plain text file.
--
-- There are cases when unload events are not logged, for example, when
-- shutting down the computer with mpv processed still open, as observed on
-- both Linux and Windows.
-- One could take advantage of this behavior to restore the closed on shutdown
-- mpv processes by parsing the log file and finding paths that have not been
-- unloaded yet, adding fake unloading entries for them to the log and opening
-- those paths in mpv (which will cause them to be logged as loaded).
--
-- This logging method is not safe from race conditions as no locking of any
-- kind is used. It is hard to come up with a locking method that is
-- cross-platform and doesn't require adding 3rd-party libraries. If you know
-- of a cross-platform way to prevent file write race conditions without adding
-- extra libraries/modules/executables while still maintaining one log file
-- (instead of the log entries being scattered among many files), then please
-- contact me.
-- I have not observed any race conditions in practice on a single user system,
-- so the script works great for me. Perhaps because I never load/unload files
-- in mpv at the exactly same time, which is what should trigger the race
-- condition. It's hard to intentionally do so with keyboard and mouse, and
-- when scripting to run many mpv processes, I add a small delay between them.

local path
local title
local loaded = false

local function ljust(str, len, char)
  if char == nil then char = ' ' end
  return str .. string.rep(char, len - #str)
end

local function log(event)
  local f = io.open(debug.getinfo(1).source:match("@?(.*/)") .. '../history.log', 'a+')
  f:write(('[%s] \t%s\t%s \t%s\n'):format(os.date('%Y-%m-%d %H:%M:%S'), ljust(event, 9), ljust(path, 56), title))
  f:close()
end

local function log_file_loaded(event)
  path = mp.get_property('path')
  title = mp.get_property_osd('media-title')
  loaded = true
  log('loaded')
end

local function log_end_file(event)
  if not loaded then return end
  loaded = false
  log('unloaded')
end

mp.register_event('file-loaded', log_file_loaded)
mp.register_event('end-file',    log_end_file)
