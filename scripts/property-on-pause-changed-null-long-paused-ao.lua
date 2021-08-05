-- MIT License
--
-- Copyright (c) 2021 Maxim Biro <nurupo.contributions@gmail.com>
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

-- Removes the audio output (set ao null) after mpv has been paused for some
-- time, restoring it back on resume.
--
-- Useful for removing pulseaudio connections for long paused videos.
--
-- If ao was null to begin with - this script does nothing, as it makes no
-- sense to go from null to null and then restore back to null.
-- If the video was paused for long enough for this script to set ao to null
-- but then something outside of this script changed it to a non-null, this is
-- interpreted as overriding this script, so the script gives up on restoring
-- ao to the value it had before it was removed.

require 'mp.msg'

local pause_timeout_seconds = 60

local timer = nil
local ao = 'null'
local needs_restore = false

local function on_pause_timeout()
    timer:kill()
    ao = mp.get_property('ao')
    if ao == 'null' then
        return
    end
    mp.msg.info('Removing audio output due to being paused for ' .. timer.timeout .. ' seconds')
    mp.set_property('ao', 'null')
    needs_restore = true
end

timer = mp.add_timeout(pause_timeout_seconds, on_pause_timeout)
timer:kill()

local function on_pause_changed(_, paused)
    timer:kill()
    if paused then
        timer:resume()
    else
        if needs_restore and mp.get_property('ao') == 'null' then
            mp.set_property('ao', ao)
            mp.msg.info('Restoring the audio output')
        end
    end
    needs_restore = false
end

-- don't restore audio output if it was changed outside of this script
local function on_audio_reconfig()
    if needs_restore and mp.get_property('ao') ~= 'null' then
        mp.msg.info("Won't be restoring the audio output as it was changed outside of this script")
        needs_restore = false
    end
end

mp.observe_property('pause', 'bool', on_pause_changed)
mp.register_event('audio-reconfig', on_audio_reconfig)
