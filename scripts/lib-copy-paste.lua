-- MIT License
--
-- Copyright (c) 2020-2023 Maxim Biro <nurupo.contributions@gmail.com>
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
-- Linux and Windows only. On Linux, requires xclip to be installed. On Windows, requires Windows 10 (no idea if it works on earlier Windowses).

local cp = {}

local copy_cmd = package.config:sub(1,1) == '\\' and         'powershell -window hidden -command "Get-Clipboard"' or -- Windows
                 os.execute('xclip -h > /dev/null 2>&1') and 'xclip -selection clipboard -o'                         -- Linux

local paste_fn = function (str) return  package.config:sub(1,1) == '\\' and         os.execute('powershell -window hidden -command "Write-Host -NoNewLine ""' .. str .. '""" | clip.exe') or -- Windows
                                        os.execute('xclip -h > /dev/null 2>&1') and os.execute('echo -n "' .. str .. '" | xclip -selection clipboard')                                       -- Linux
                 end

function cp.copy(str, verbose)
    if not str then
        mp.osd_message('Error: Failed to copy - nothing to copy!', 10)
        mp.msg.error('Failed to copy - nothing to copy!')
        return false
    end
    if not paste_fn(str) then
        mp.osd_message('Error: Failed to copy! Do you have xclip installed?', 10)
        mp.msg.error('Failed to copy! Do you have xclip installed?')
        return false
    end
    if verbose then
        mp.osd_message('Copied: ' .. str, 3)
        mp.msg.info('Copied: ' .. str)
    end
    return true
end

function cp.paste(verbose)
    local p = io.popen(copy_cmd, 'r')
    -- remove "file://" if present
    local str = p:read()
    if not p:close() then
        mp.osd_message('Error: Failed to paste! Do you have xclip installed?', 10)
        mp.msg.error('Failed to paste! Do you have xclip installed?')
        return nil
    end
    if verbose then
        mp.osd_message('Pasted: ' .. str, 3)
        mp.msg.info('Pasted: ' .. str)
    end
    return str
end

return cp
