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

-- Module for copying and pasting.
--
-- Linux and Windows only.
-- On Linux, requires xclip to be installed.
-- On Windows, requires powershell and tested to work on Windows 10.

local cp = {}

local powershell_utf8 = '$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding; '

-- gets a string as an argument. it's also provided as the stdin.
-- if using the argument, make sure to escape it well, to prevent command
-- injections. prefer using the stdin to avoid the headache of argument
-- escaping.
-- Note that stdin doesn't work on Windows yet: https://github.com/mpv-player/mpv/issues/8503
local set_clipboard_cmd_fns = {
    windows = function(s) return {'powershell', '-command', powershell_utf8 .. "Set-Clipboard -Value '" .. s:gsub("'", "''") .. "'"} end,
    linux   = function(s) return {'xclip', '-selection', 'clipboard', '-i'} end,
}

local get_clipboard_cmd_fns = {
    windows = function() return {'powershell', '-command', powershell_utf8 .. 'Get-Clipboard'} end,
    linux   = function() return {'xclip', '-selection', 'clipboard', '-o'} end,
}

local function get_platform_value(platform_table)
    local platform = mp.get_property_native('platform')
    if not platform_table[platform] then
        mp.osd_message('Error: Unsupported platform "' .. platform .. '"', 10)
        mp.msg.error('Unsupported platform "' .. platform .. '"')
        return nil
    end
    return platform_table[platform]
end

local function run_platform_cmd(cmd_fn_platform_table, cmd_fn_args, cmd_stdin, operation)
    local cmd_fn = get_platform_value(cmd_fn_platform_table)
    if not cmd_fn then
        return false, nil
    end
    local cmd = cmd_fn(unpack(cmd_fn_args))
    -- use mpv's subproccess command over Lua's io.popen(), to avoid the
    -- cmd.exe window poping up on Windows
    local result = mp.command_native({
        name = "subprocess",
        playback_only = false,
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
        stdin_data = cmd_stdin,
    })
    if not result or result.killed_by_us or result.status ~= 0 then
        mp.osd_message('Error: Failed to ' .. operation .. '!', 10)
        mp.msg.error('Failed to ' .. operation .. '!')
        if result then
            if result.stderr then
                mp.msg.error(result.stderr)
            end
            if result.error_string == 'init' then
                mp.msg.error('Couldn\'t run "' .. cmd[1] .. '", is the program installed?')
            end
        end
        return false, nil
    end
    return true, result.stdout
end

function cp.copy(str, verbose)
    if not str then
        mp.osd_message('Error: Failed to copy - nothing to copy!', 10)
        mp.msg.error('Failed to copy - nothing to copy!')
        return false
    end
    local success, _ = run_platform_cmd(set_clipboard_cmd_fns, {str}, str, 'copy')
    if not success then
        return false
    end
    if verbose then
        mp.osd_message('Copied: ' .. str, 3)
        mp.msg.info('Copied: ' .. str)
    end
    return true
end

function cp.paste(verbose)
    local success, str = run_platform_cmd(get_clipboard_cmd_fns, {}, nil, 'paste')
    if not success then
        return nil
    end
    if mp.get_property_native('platform') == 'windows' then
        -- remove the trailing \r\n
        if str:len() >= 2 and str:sub(-2, -1) == '\r\n' then
            str = str:sub(1, -3)
        end
    end
    if verbose then
        mp.osd_message('Pasted: ' .. str, 3)
        mp.msg.info('Pasted: ' .. str)
    end
    return str
end

return cp
