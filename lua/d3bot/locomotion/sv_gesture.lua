-- Copyright (C) 2020 David Vogel
-- 
-- This file is part of D3bot.
-- 
-- D3bot is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- D3bot is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with D3bot.  If not, see <http://www.gnu.org/licenses/>.

local D3bot = D3bot
local LOCOMOTION = D3bot.Locomotion

-- Add new locomotion controller
function LOCOMOTION.Gesture(bot, mem, gestureName)
	-- Init
	mem.Locomotion = {}

	-- BUG: Gestures don't seem to work with this kind of bot entities
	local duration = bot:SetSequence(gestureName)
	bot:ResetSequenceInfo()
	bot:SetCycle(0)
	bot:SetPlaybackRate(1)

	coroutine.wait(duration)

	-- Cleanup
	mem.Locomotion = nil
end