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
local UTIL = D3bot.Util
local BRAINS = D3bot.Brains
local LOCOMOTION = D3bot.Locomotion

-- Add new brain class.
BRAINS.GENERAL = BRAINS.GENERAL or {}
local THIS_BRAIN = BRAINS.GENERAL

------------------------------------------------------
--						Static						--
------------------------------------------------------

-- This will assign the brain to the given bot (and the corresponding mem).
function THIS_BRAIN:AssignToBot(bot, mem)
	local brain = {Bot = bot, Mem = mem}

	setmetatable(brain, self)
	self.__index = self

	-- Add main handler
	brain.MainCoroutine = coroutine.create(function() brain:Think_Coroutine(bot, mem) end)

	mem.Brain = brain
	return true
end

------------------------------------------------------
--						Methods						--
------------------------------------------------------

-- Think coroutine. Put all the important stuff in here.
function THIS_BRAIN:Think_Coroutine(bot, mem)

	-- Walk in an arc for 3 seconds
	LOCOMOTION.SinCosTest(bot, mem, 3)

	-- Walk in some random direction for 3 seconds
	LOCOMOTION.RandomWalkTest(bot, mem, 3)

	-- Wait 2 seconds
	coroutine.wait(2)

	-- A new brain will be assigned automatically after here
end

-- Think callback. Ideally this will resume coroutine(s).
function THIS_BRAIN:Callback(bot, mem)
	-- Resume coroutine, catch and print any error
	local succ, msg = coroutine.resume(self.MainCoroutine)
	if not succ then
		-- Coroutine ended unexpectedly
		print(string.format("%s %s of bot %s failed: %s", D3bot.PrintPrefix, self.MainCoroutine, bot:Nick(), msg))
		-- Assign ON_ERROR brain that does some stupid animations to prevent the errornous brain to be assigned again immediately (Spam prevention)
		BRAINS.ON_ERROR:AssignToBot(bot, mem)
		return false
	end

	-- Delete brain when the coroutine ends
	if coroutine.status(self.MainCoroutine) == "dead" then
		mem.Brain = nil
	end

	return true
end
