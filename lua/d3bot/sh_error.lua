-- Copyright (C) 2020-2021 David Vogel
--
-- This file is part of D3bot.
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- Go like error handling, just without error wrapping.

local D3bot = D3bot

------------------------------------------------------
--		Static
------------------------------------------------------

---@class D3botERROR
---@field Message string @The error message as a formatted string.
local ERROR = D3bot.ERROR
ERROR.__index = ERROR

---Get new instance of an error object with the given formatted message.
---@param format string
--@vararg any
---@return D3botERROR err
function ERROR:New(format, ...)
	local params = {...}
	local message = string.format(format, unpack(params))

	local obj = setmetatable({
		Message = message,
	}, self)

	return obj
end

------------------------------------------------------
--		Methods
------------------------------------------------------

---Return the error message as string.
---@return string
function ERROR:Error()
	return self.Message
end

---Define metamethod for string conversion.
---@return string
function ERROR:__tostring()
	return self:Error()
end
