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

-- All navmesh edit functions in here are available on the client and server realm.
-- But regardless from which realm they are called, they will always edit the main navmesh on the server side.
-- Basically client --> server communication.

local D3bot = D3bot
local NAV_MAIN = D3bot.NavMain
local NAV_EDIT = D3bot.NavEdit

------------------------------------------------------
--		CreateTriangle3P
------------------------------------------------------

---Create a triangle in the main navmesh.
---@param ply GPlayer
---@param p1 GVector
---@param p2 GVector
---@param p3 GVector
function NAV_EDIT.CreateTriangle3P(ply, p1, p2, p3)
	if SERVER then
		-- Only he who wields the weapon has the power.
		if not ply:HasWeapon("weapon_d3_navmesher") then return end
		-- Get or create navmesh.
		local navmesh = NAV_MAIN:ForceNavmesh()

		local _, err = navmesh:FindOrCreateTriangle3P(p1, p2, p3)
		if err then ply:ChatPrint(string.format("%s Failed to create triangle: %s", D3bot.PrintPrefix, err)) end

		-- Try to garbage collect entities.
		navmesh:_GC()

	elseif CLIENT then
		net.Start("D3bot_Nav_Edit_CreateTriangle3P")
		net.WriteVector(p1)
		net.WriteVector(p2)
		net.WriteVector(p3)
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString("D3bot_Nav_Edit_CreateTriangle3P")
	net.Receive("D3bot_Nav_Edit_CreateTriangle3P",
		function(len, ply)
			local p1, p2, p3 = net.ReadVector(), net.ReadVector(), net.ReadVector()
			NAV_EDIT.CreateTriangle3P(ply, p1, p2, p3)
		end
	)
end

------------------------------------------------------
--		CreateAirConnection2E
------------------------------------------------------

---Create an air connection in the main navmesh.
---@param ply GPlayer
---@param e1ID number | string
---@param e2ID number | string
function NAV_EDIT.CreateAirConnection2E(ply, e1ID, e2ID)
	if SERVER then
		-- Only he who wields the weapon has the power.
		if not ply:HasWeapon("weapon_d3_navmesher") then return end
		-- Get or create navmesh.
		local navmesh = NAV_MAIN:ForceNavmesh()

		local e1, e2 = navmesh:FindEdgeByID(e1ID), navmesh:FindEdgeByID(e2ID)
		if not e1 or not e2 then
			ply:ChatPrint(string.format("%s Failed to create air connection: Can't find all needed edges", D3bot.PrintPrefix))
			return
		end

		local _, err = navmesh:FindOrCreateAirConnection2E(e1, e2)
		if err then ply:ChatPrint(string.format("%s Failed to create air connection: %s", D3bot.PrintPrefix, err)) end

		-- Try to garbage collect entities.
		navmesh:_GC()

	elseif CLIENT then
		net.Start("D3bot_Nav_Edit_CreateAirConnection2E")
		net.WriteTable({e1ID, e2ID})
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString("D3bot_Nav_Edit_CreateAirConnection2E")
	net.Receive("D3bot_Nav_Edit_CreateAirConnection2E",
		function(len, ply)
			local e1ID, e2ID = unpack(net.ReadTable())
			NAV_EDIT.CreateAirConnection2E(ply, e1ID, e2ID)
		end
	)
end

------------------------------------------------------
--		RemoveByID
------------------------------------------------------

---Remove element by id.
---@param ply GPlayer
---@param id number | string
function NAV_EDIT.RemoveByID(ply, id)
	if SERVER then
		-- Only he who wields the weapon has the power.
		if not ply:HasWeapon("weapon_d3_navmesher") then return end
		-- Get or create navmesh.
		local navmesh = NAV_MAIN:ForceNavmesh()

		local entity = navmesh:FindByID(id)
		if entity then
			entity:Delete()
		end
		navmesh:_GC()

	elseif CLIENT then
		net.Start("D3bot_Nav_Edit_RemoveByID")
		net.WriteTable({id})
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString("D3bot_Nav_Edit_RemoveByID")
	net.Receive("D3bot_Nav_Edit_RemoveByID",
		function(len, ply)
			local id = unpack(net.ReadTable())
			NAV_EDIT.RemoveByID(ply, id)
		end
	)
end

------------------------------------------------------
--		SetFlipNormalByID
------------------------------------------------------

---Flip normal of triangle.
---@param ply GPlayer
---@param id number | string
---@param state boolean
function NAV_EDIT.SetFlipNormalByID(ply, id, state)
	if SERVER then
		-- Only he who wields the weapon has the power.
		if not ply:HasWeapon("weapon_d3_navmesher") then return end
		-- Get or create navmesh.
		local navmesh = NAV_MAIN:ForceNavmesh()

		local triangle = navmesh:FindTriangleByID(id)
		if triangle then
			triangle:SetFlipNormal(state)
		end

	elseif CLIENT then
		net.Start("D3bot_Nav_Edit_SetFlipNormalByID")
		net.WriteTable({id})
		net.WriteBool(state)
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString("D3bot_Nav_Edit_SetFlipNormalByID")
	net.Receive("D3bot_Nav_Edit_SetFlipNormalByID",
		function(len, ply)
			local id = unpack(net.ReadTable())
			local state = net.ReadBool()
			NAV_EDIT.SetFlipNormalByID(ply, id, state)
		end
	)
end

------------------------------------------------------
--		RecalcFlipNormalByID
------------------------------------------------------

---Flip normal of triangle.
---@param ply GPlayer
---@param id number | string
function NAV_EDIT.RecalcFlipNormalByID(ply, id)
	if SERVER then
		-- Only he who wields the weapon has the power.
		if not ply:HasWeapon("weapon_d3_navmesher") then return end
		-- Get or create navmesh.
		local navmesh = NAV_MAIN:ForceNavmesh()

		local triangle = navmesh:FindTriangleByID(id)
		if triangle then
			triangle:RecalcFlipNormal()
		end

	elseif CLIENT then
		net.Start("D3bot_Nav_Edit_RecalcFlipNormalByID")
		net.WriteTable({id})
		net.SendToServer()
	end
end

if SERVER then
	util.AddNetworkString("D3bot_Nav_Edit_RecalcFlipNormalByID")
	net.Receive("D3bot_Nav_Edit_RecalcFlipNormalByID",
		function(len, ply)
			local id = unpack(net.ReadTable())
			NAV_EDIT.RecalcFlipNormalByID(ply, id)
		end
	)
end
