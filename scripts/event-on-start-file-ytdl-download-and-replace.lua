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

-- This script solves two problems:
--   1. mpv taking forever to load a video via its ytdl integration as mpv uses
--      its own downloader which is not as fast as ytdl's built-in one.
--   2. if you have many mpvs open with yt videos and want to reboot the
--      system, you would have to close all of the mpvs all and re-open them
--      back once rebooted, which would cause them to re-download the videos,
--      which is widely inefficient and time consuming.
--
-- When an http(s) URL is opened in mpv, this script rapidly downloads the
-- video in the background using the ytdl binary, meanwhile mpv slowly
-- downloads and plays the video via its ytdl integration. Once ytdl has
-- downloaded the video in the background the script replaces the video
-- currently opened in mpv (the video being downloaded via the slow mpv
-- download method) with the one ytdl has downloaded, continuing from the
-- current position, as if nothing has happened.

local msg     = require 'mp.msg'
local options = require 'mp.options'
local utils   = require 'mp.utils'

package.path = debug.getinfo(1).source:match("@?(.*/)") .. '?.lua;' .. package.path
local ytdl = require('lib-ytdl-path')

local o = {
    config_live = '',
    config_vod = '',
    use_ytdl_format = true,
}
options.read_options(o)

if not o.config_live or o.config_live == ''
    or not o.config_vod or o.config_vod == '' then
    msg.error('config_live or config_vod are not set')
    return
end

local download_async_command = nil

local function is_url(str)
    return string.match(str, "^https?://")
end

local function get_ytdl_json_dump(url)
    local ytdl_path = ytdl.ytdl_path()
    local command_args = {ytdl_path, "--dump-json", "--config-location", o.config_vod, "--", url}
    local ytdl_format = mp.get_property("options/ytdl-format")
    if o.use_ytdl_format and ytdl_format then
        table.insert(command_args, 2, ytdl_format)
        table.insert(command_args, 2, "--format")
    end
    local result = mp.command_native({
        name = "subprocess",
        playback_only = false,
        args = command_args,
        capture_stdout = true,
        capture_stderr = true,
    })
    if not result or result.status ~= 0 then
        msg.error("Failed to determine video's live status")
        return nil
    end
    local json, _ = utils.parse_json(result.stdout)
    if not json then
        msg.error("Failed to parse json")
        msg.error('stdout:')
        msg.error(result.stdout)
        msg.error('stderr:')
        msg.error(result.stderr)
        return nil
    end
    return json
end

local function load_downloaded_video(downloaded_video_path, is_live, download_start_time_pos)
    local position = mp.get_property_number("time-pos")
    -- the time-pos of a live stream starts counting not from when we opened
    -- the steam, but from when the steam has started.
    -- e.g. the download might have started when the stream was at 01:00:00,
    -- so our local file's 00:00:00 is actually 01:00:00 of the stream, so we
    -- need to subtract 01:00:00 from the curent time-pos to correctly
    -- translate the stream time to the time in the file.
    if is_live and path and download_start_time_pos and position > download_start_time_pos then
        position = position - download_start_time_pos
    end
    local start = position and ("start=" .. position .. ",") or ""
    local commandv_args = {"loadfile", downloaded_video_path, "replace", 0, start ..
                           "script-opts-add=[" ..
                                "event_on_file_loaded_resume-disable=yes," ..
                                "event_on_file_loaded_show_media_title-disable=yes" ..
                           "]"
    }
    local success = mp.commandv(unpack(commandv_args))
    -- fallback for mpv < v0.38
    if not success then
        table.remove(commandv_args, 4)
        mp.commandv(unpack(commandv_args))
    end
end

local function file_exists(path)
    local info = utils.file_info(path)
    return info and info.is_file or false
end

local function download_video_async(url, is_live, callback)
    local ytdl_path = ytdl.ytdl_path()
    local config_file = is_live and o.config_live or o.config_vod
    local command_args = {ytdl_path, "--no-simulate", "--print", "after_move:%(filepath)j", "--config-location", config_file, "--", url}
    local ytdl_format = mp.get_property("options/ytdl-format")
    if o.use_ytdl_format and ytdl_format then
        table.insert(command_args, 2, ytdl_format)
        table.insert(command_args, 2, "--format")
    end
    return mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        args = command_args,
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result, error)
        if not success then
            msg.error("Failed to start the video download")
            if result then
                msg.error('stdout:')
                msg.error(result.stdout)
                msg.error('stderr:')
                msg.error(result.stderr)
            end
            mp.osd_message('Error: Download failed')
            return
        end
        if not result.killed_by_us and result.status ~= 0 then
            msg.error("ytdl failed")
            msg.error('stdout:')
            msg.error(result.stdout)
            msg.error('stderr:')
            msg.error(result.stderr)
            mp.osd_message('Error: Download failed')
            return
        end
        if result.killed_by_us then
            msg.info("Cancelled the video download")
            return
        end
        downloaded_video_path, _ = utils.parse_json(result.stdout)
        if not downloaded_video_path then
            msg.error("Failed to parse json / extract the downloaded video path from:")
            msg.error('stdout:')
            msg.error(result.stdout)
            msg.error('stderr:')
            msg.error(result.stderr)
            mp.osd_message('Error: Download failed')
            return
        end
        if not file_exists(downloaded_video_path) then
            msg.error("Failed to open \"" .. downloaded_video_path .. "\": " .. error)
            mp.osd_message('Error: Download failed')
            return
        end
        callback(downloaded_video_path)
    end)
end

local function on_start_file()
    if download_async_command then
        mp.abort_async_command(download_async_command)
        download_async_command = nil
    end
    local path = mp.get_property("path")
    if not is_url(path) then
        return
    end
    local json_dump = get_ytdl_json_dump(path)
    if not json_dump then
        return
    end
    -- don't attempt to download a non-live video if the file already exists,
    -- just load the existing file
    if not json_dump.is_live and json_dump.filename and file_exists(json_dump.filename) then
        msg.info('Already downloaded')
        mp.osd_message('Already downloaded', 5)
        load_downloaded_video(json_dump.filename, false, 0)
        return
    end
    local download_start_time_pos = mp.get_property_number("time-pos") or 0
    local download_start_time = os.time()
    download_async_command = download_video_async(path, json_dump.is_live, function(downloaded_video_path)
        local download_duration_seconds = os.difftime(os.time(), download_start_time)
        local f, _ = io.open(downloaded_video_path, 'r')
        local download_filesize_bytes = f:seek("end")
        f:close()
        local download_stats = string.format("Downloaded %.1fMiB in %ds (%.1fMiB/s)",
                                             download_filesize_bytes / 1024 / 1024,
                                             download_duration_seconds,
                                             download_filesize_bytes / download_duration_seconds / 1024 / 1024)
        msg.info(download_stats)
        mp.osd_message(download_stats, 8)
        load_downloaded_video(downloaded_video_path, json_dump.is_live, download_start_time_pos)
    end)
end

mp.register_event("start-file", on_start_file)
