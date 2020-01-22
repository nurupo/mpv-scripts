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
-- 1, 1/2 and 1/4 are obvious.
-- 1/1.5, 1/3 and 1/6, assuming the input is on 1920x1080, will resize it to
-- 1, 1/2 and 1/3 of 1280x720. The reason for this is that if I don't want to
-- watch a 1920x1080 video in full screen, 1/2 of it is too small, but 1/1.5,
-- i.e. 1280x720 - just perfect. 1/3 is useful when splitting the screen on 2/3
-- for a main window, e.g. a code editor, and 1/3 for a video on a side. 1/6 is
-- just for the completeness, to match 1/4.

function step_window_scale(increment)
    local scales = {
        1.0/6, 1.0/4, 1.0/3, 1.0/2, 1/1.5, 1.0/1
    }
    local scale = mp.get_property_number("window-scale") * (increment and 1.1 or 0.9)
    for i=1, #scales do
        if (increment and scales[i] > scale) or ((not increment and scales[i] >= scale) and (i > 1)) then
            scale = increment and scales[i] or scales[i-1]
            break
        end
    end
    if scale > 1.0 then scale = 1.0 end
    mp.command("set window-scale " .. scale)
end

mp.add_key_binding(nil, "step-window-scale-up", function() step_window_scale(true) end)
mp.add_key_binding(nil, "step-window-scale-down", function() step_window_scale(false) end)
