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

-- Always play newly opened files.
--
-- You can force it to start paused the first time by passing
-- --script-opts=event-on-file-loaded-resume-startPaused=yes option to mpv.

require 'mp.options'

local options = {
    startPaused = false,
    disable = false,
}
read_options(options)

local function resume()
    -- this opion might get set at the run-time
    options.disable = mp.get_opt(mp.get_script_name():gsub("_", "-") .. '-disable')
    if options.disable == 'yes' then
        return
    end
    mp.set_property_bool('pause', options.startPaused)
    options.startPaused = false
end

mp.register_event('file-loaded', resume)
