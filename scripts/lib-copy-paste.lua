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

-- Module for copying and pasting.
--
-- Linux-only. Requires xclip to be installed.

local cp = {}

function cp.copy(str, verbose)
    if not os.execute('echo -n "' .. str .. '" | xclip -selection clipboard') then
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
    local p = io.popen('xclip -selection clipboard -o', 'r')
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
