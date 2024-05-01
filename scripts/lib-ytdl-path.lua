-- SPDX-License-Identifier: LGPL-2.1-or-later
--
-- Copyright (c) 2024 the mpv developers
-- Copyright (c) 2024 Maxim Biro <nurupo.contributions@gmail.com>
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library. If not, see <http://www.gnu.org/licenses/>.

-- Module for finding the ytdl binary location.
--
-- Since it doesn't seem to be possible to access ytdl_hook.lua's ytdl.path
-- varialbe from another script, we reuse the ytdl binary finding code from
-- https://github.com/mpv-player/mpv/blob/v0.37.0/player/lua/ytdl_hook.lua
-- so that this script returns the same ytdl binary ytdl_hook.lua uses. The
-- relevant code portions are copied as is, with minimal modifications, to make
-- it easier to update the script once ytdl_hook.lua changes.

local m = {}

local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    exclude = "",
    try_ytdl_first = false,
    use_manifests = false,
    all_formats = false,
    force_all_formats = true,
    thumbnails = "none",
    ytdl_path = "",
}

local ytdl = {
    path = "",
    paths_to_search = {"yt-dlp", "yt-dlp_x86", "youtube-dl"},
    searched = false,
    blacklisted = {}
}

options.read_options(o, "ytdl_hook", function()
    ytdl.blacklisted = {} -- reparse o.exclude next time
    ytdl.searched = false
end)

local function platform_is_windows()
    return mp.get_property_native("platform") == "windows"
end

local function exec(args)
    msg.debug("Running: " .. table.concat(args, " "))

    return mp.command_native({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true,
    })
end

function m.ytdl_path()
    local command = {"", "--version"}

    local result
    if not ytdl.searched then
        local separator = platform_is_windows() and ";" or ":"
        if o.ytdl_path:match("[^" .. separator .. "]") then
            ytdl.paths_to_search = {}
            for path in o.ytdl_path:gmatch("[^" .. separator .. "]+") do
                table.insert(ytdl.paths_to_search, path)
            end
        end

        for _, path in pairs(ytdl.paths_to_search) do
            -- search for youtube-dl in mpv's config dir
            local exesuf = platform_is_windows() and not path:lower():match("%.exe$") and ".exe" or ""
            local ytdl_cmd = mp.find_config_file(path .. exesuf)
            if ytdl_cmd then
                msg.verbose("Found youtube-dl at: " .. ytdl_cmd)
                ytdl.path = ytdl_cmd
                command[1] = ytdl.path
--                result = exec(command)
                break
            else
                msg.verbose("No youtube-dl found with path " .. path .. exesuf .. " in config directories")
                command[1] = path
                result = exec(command)
                if result.error_string == "init" then
                    msg.verbose("youtube-dl with path " .. path .. " not found in PATH or not enough permissions")
                else
                    msg.verbose("Found youtube-dl with path " .. path .. " in PATH")
                    ytdl.path = path
                    break
                end
            end
        end

        ytdl.searched = true
    end

    return ytdl.path == "" and nil or ytdl.path
end

return m
