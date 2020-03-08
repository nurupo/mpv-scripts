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

-- Resizes the window in specific steps.
--
-- Set `screen_height` to your screen's max height.
--
-- Resizes the window to 1/1, 1/1.5, 1/2, etc. of your screen, allowing to
-- stack windows side by side, as they would be resized to the same resolution
-- even if they are of different original resolution. Well, assuming the videos
-- have the same aspect ratio, otherwise only their height would be the same
-- and not the width.

local screen_height = 1080
local scales = {
    1/6, 1/5, 1/4, 1/3, 1/2, 1/1.5, 1/1
}
-- window-scale can't store 1/3 and such, introducing error
local scale_error_correction = (scales[2]-scales[1])*screen_height/2

local function step_window_scale(increment)
    local current_scale = mp.get_property_number("current-window-scale")
    local video_height = mp.get_property("height")
    local output_height = current_scale * video_height
    for i=1, #scales do
        if (increment and scales[i]*screen_height > output_height+scale_error_correction) or ((not increment and scales[i]*screen_height >= output_height-scale_error_correction) and (i > 1)) then
            new_scale = screen_height/video_height * (increment and scales[i] or scales[i-1])
            break
        end
    end
    -- Workaround window-scale having the default value of 1 even though the
    -- current-window-scale is 0.667. Setting window-scale to 1 - its current
    -- value - does nothing, so we want to set it to 0.667 first and only then
    -- set it to the 1 scaling to actually force the 1 scaling.
    if (math.abs(current_scale*screen_height-new_scale*screen_height) > scale_error_correction) then
        mp.command("set window-scale " .. current_scale)
    end
    mp.command("set window-scale " .. new_scale)
end

mp.add_key_binding(nil, "step-window-scale-up", function() step_window_scale(true) end)
mp.add_key_binding(nil, "step-window-scale-down", function() step_window_scale(false) end)
