-- MIT License
--
-- Copyright (c) 2024 Maxim Biro <nurupo.contributions@gmail.com>
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

-- Deletes the currently loaded file, as long as it's in one of the the
-- base_path locations, switching to the next item in the playlist (because
-- opened files can't be deleted on Windows).
--
-- Use
-- --script-opts-add=event_on_end_file_delete-base_path="C:\foo\;D:\bar\" on Windows
-- --script-opts-add=event_on_end_file_delete-base_path="/tmp/foo:/tmp/bar/" on Unix
-- to specify base paths.
--
-- Note that on UNIX systems the delimiter is ':' instead of ';', as per:
-- https://mpv.io/manual/master/#string-list-and-path-list-options
-- https://github.com/mpv-player/mpv/blob/release/0.38/DOCS/man/mpv.rst#string-list-and-path-list-options
--
-- Note that the script simply checks if the file path starts with one of paths
-- in the base_path, as such it's important to include the trailing \ or / and
-- the file can be anywhere under that bath.

local msg     = require 'mp.msg'
local options = require 'mp.options'
local utils   = require 'mp.utils'

local o = {
    base_path = '',
}
options.read_options(o)

local path = nil

local function is_url(str)
    return string.match(str, "^https?://")
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

local function parse_file_list(option)
    local file_list = {}
    if not option or option == '' then
        return file_list
    end
    local separator = ';'
    if mp.get_property_native("platform") == "windows" then
        separator = ';'
        option = option:gsub('/', '\\')
    end
    for path in option:gmatch("[^" .. separator .. "]+") do
        table.insert(file_list, path)
    end
    return file_list
end

local function log_error(str, delay)
    mp.osd_message('Error: ' .. str, delay)
    msg.error(str:gsub('\n', ' '))
end

local function log_info(str, delay)
    mp.osd_message(str, delay)
    msg.info(str:gsub('\n', ' '))
end

local function delete_file(reason)
    if not path then
        msg.error('No path set')
        return
    end
    if is_url(path) then
        msg.error('Can\'t delete, the path is an URL')
        return
    end
    if not file_exists(path) then
        msg.error('Can\'t delete, the file does not exist')
        return
    end
    if o.base_path == nil or o.base_path == '' then
        log_error('Can\'t delete without the base_path set', 5)
        return
    end
    local is_in_base_path = false
    local base_path_list = parse_file_list(o.base_path)
    for _, bp in ipairs(base_path_list) do
        is_in_base_path = select(1, string.find(path, bp, 1, true)) == 1
        if is_in_base_path then
            break
        end
    end
    if not is_in_base_path then
        return
    end
    if os.remove(path) then
        log_info('Deleted\n' .. path, 5)
    else
        log_error('Failed to delete\n' .. path, 5)
    end
end

local function record_path()
    path = mp.get_property("path")
end

mp.register_event('end-file', delete_file)
mp.register_event('file-loaded', record_path)
