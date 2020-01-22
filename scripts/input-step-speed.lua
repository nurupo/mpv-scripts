-- Copyright © 2018-2019 VLC authors and VideoLAN
-- Copyright (c) 2020 Maxim Biro <nurupo.contributions@gmail.com>
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program; if not, write to the Free Software Foundation,
-- Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.

-- Mimics VLC speed increment/decrement steps.
--
-- mpv specific: capped at 100, since that's the max speed in mpv.

function step_sepeed(increment)
    -- https://github.com/videolan/vlc/blob/65683cd771684e85c181172cb0b2cb972f3553b5/src/player/player.c#L1280
    local rates = {
        1.0/64, 1.0/32, 1.0/16, 1.0/8, 1.0/4, 1.0/3, 1.0/2, 2.0/3,
        1.0/1,
        3.0/2, 2.0/1, 3.0/1, 4.0/1, 8.0/1, 16.0/1, 32.0/1, 64.0/1, 100/1
    }
    local rate = mp.get_property_number("speed") * (increment and 1.1 or 0.9)
    for i=1, #rates do
        if (increment and rates[i] > rate) or ((not increment and rates[i] >= rate) and (i > 1)) then
            rate = increment and rates[i] or rates[i-1]
            break
        end
    end
    if rate > 64.0 then rate = 100 end
    mp.command("set speed " .. rate)
end

mp.add_key_binding(nil, "step-speed-up", function() step_sepeed(true) end)
mp.add_key_binding(nil, "step-speed-down", function() step_sepeed(false) end)
