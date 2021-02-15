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

-- List of concommands that are available on client (With autocompletion) and can run stuff on the server side.

local D3bot = D3bot
local CONCOMMAND = D3bot.CONCOMMAND
local CONCOMMANDS = D3bot.ConCommands
local NAV_FILE = D3bot.NavFile

-- Give a player the navmeshing SWEP.
CONCOMMANDS.EditMesh = CONCOMMAND:New("d3bot_editmesh", nil, "Gives yourself the navmeshing SWEP")
function CONCOMMANDS.EditMesh:OnServer(ply, cmd, args, argStr)
	if not ply:IsSuperAdmin() then return end

	ply:Give("weapon_d3_navmesher")
end

-- Save the main navmesh to disk.
CONCOMMANDS.SaveMesh = CONCOMMAND:New("d3bot_savemesh", nil, "Saves the navmesh of the current map to disk")
function CONCOMMANDS.SaveMesh:OnServer(ply, cmd, args, argStr)
	if not ply:IsSuperAdmin() then return end

	local err = NAV_FILE.SaveMainNavmesh()
	if err then ply:ChatPrint(string.format("%s Couldn't save current main navmesh: %s", D3bot.PrintPrefix, err)) end
end

-- Load the main navmesh from disk.
CONCOMMANDS.LoadMesh = CONCOMMAND:New("d3bot_loadmesh", nil, "Loads the navmesh for the current map from disk")
function CONCOMMANDS.LoadMesh:OnServer(ply, cmd, args, argStr)
	if not ply:IsSuperAdmin() then return end

	local err = NAV_FILE.LoadMainNavmesh()
	if err then ply:ChatPrint(string.format("%s Couldn't load navmesh for the current map: %s", D3bot.PrintPrefix, err)) end
end

-- Changes the current edit mode of the player's navmeshing SWEP to the given mode.
CONCOMMANDS.EditMode = CONCOMMAND:New("d3bot_editmode", nil, "Changes your SWEP's edit mode")
function CONCOMMANDS.EditMode:OnShared(ply, cmd, args, argStr)
	local wep = ply:GetWeapon("weapon_d3_navmesher")
	if IsValid(wep) then
		local err = wep:ChangeEditMode(argStr)
		if CLIENT and err then ply:ChatPrint(string.format("%s Failed to change edit mode: %s", D3bot.PrintPrefix, err)) end
	end
end

-- Reapplies the player's SWEP edit mode, so all values are reset.
CONCOMMANDS.EditModeReset = CONCOMMAND:New("d3bot_editmode_reset", nil, "Resets the edit mode state of your SWEP")
function CONCOMMANDS.EditModeReset:OnShared(ply, cmd, args, argStr)
	local wep = ply:GetWeapon("weapon_d3_navmesher")
	if IsValid(wep) then
		local err = wep:ResetEditMode()
		if CLIENT and err then ply:ChatPrint(string.format("%s Failed to reset edit mode: %s", D3bot.PrintPrefix, err)) end
	end
end
