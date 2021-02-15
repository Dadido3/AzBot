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

-- PubSub, server side navmesh sends change events to this, and they will be distributed to clients that are registered as subscribers.
-- Basically server --> client communication.

local D3bot = D3bot
local NAV_MAIN = D3bot.NavMain
local NAV_MESH = D3bot.NAV_MESH
local NAV_VERTEX = D3bot.NAV_VERTEX
local NAV_EDGE = D3bot.NAV_EDGE
local NAV_TRIANGLE = D3bot.NAV_TRIANGLE
local NAV_AIR_CONNECTION = D3bot.NAV_AIR_CONNECTION

---@class D3botNAV_PUBSUB @Static class or just a collection of functions with a global state.
---@field Subscribers GPlayer[]
local NAV_PUBSUB = D3bot.NavPubSub

------------------------------------------------------
--		Shared
------------------------------------------------------

------------------------------------------------------
--		Server
------------------------------------------------------

if SERVER then
	---Subscribe the client of the player to navmesh change events.
	---@param ply GPlayer
	---@return boolean
	function NAV_PUBSUB:SubscribePlayer(ply)
		self.Subscribers = self.Subscribers or {}

		table.insert(self.Subscribers, ply)

		-- Send main navmesh to new subscriber.
		local navmesh = NAV_MAIN:ForceNavmesh()
		if navmesh then
			self:SendNavmeshToSubs(navmesh, ply)
		else
			self:DeleteNavmeshFromSubs(ply)
		end

		return true
	end

	---Unsubscribe the client of the player from navmesh change events.
	---Make sure this is called before a player leaves the server.
	---@param ply GPlayer
	---@return boolean
	function NAV_PUBSUB:UnsubscribePlayer(ply)
		if not self.Subscribers then return false end

		self:DeleteNavmeshFromSubs(ply)

		if not table.RemoveByValue(self.Subscribers, ply) then return false end
		return true
	end

	---Sends the navmesh to all subscribers or to the optional plys parameter which can be a player or a table of players.
	---@param navmesh D3botNAV_MESH
	---@param plys GPlayer | GPlayer[]
	function NAV_PUBSUB:SendNavmeshToSubs(navmesh, plys)
		plys = plys or self.Subscribers
		if not plys then return end

		local navTable = navmesh:MarshalToTable()
		local navTableJSON = util.TableToJSON(navTable)
		local navTableJSONCompressed = util.Compress(navTableJSON)

		-- TODO: Allow for more than 64kB of navmesh data by chunking
		net.Start("D3bot_Nav_PubSub_Navmesh")
		net.WriteUInt(navTableJSONCompressed:len(), 16)
		net.WriteData(navTableJSONCompressed, navTableJSONCompressed:len())
		net.Send(plys)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_Navmesh")

	---Removes the navmeshes from all subscribers or from the optional plys parameter which can be a player or a table of players.
	---@param plys GPlayer | GPlayer[]
	function NAV_PUBSUB:DeleteNavmeshFromSubs(plys)
		plys = plys or self.Subscribers
		if not plys then return end

		net.Start("D3bot_Nav_PubSub_NavmeshDelete")
		net.Send(plys)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_NavmeshDelete")

	---Sends a given vertex to all the subscribers.
	---@param vertex D3botNAV_VERTEX
	function NAV_PUBSUB:SendVertexToSubs(vertex)
		if not self.Subscribers then return end

		net.Start("D3bot_Nav_PubSub_Vertex")
		net.WriteTable(vertex:MarshalToTable())
		net.Send(self.Subscribers)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_Vertex")

	---Sends a given edge to all the subscribers.
	---@param edge D3botNAV_EDGE
	function NAV_PUBSUB:SendEdgeToSubs(edge)
		if not self.Subscribers then return end

		net.Start("D3bot_Nav_PubSub_Edge")
		net.WriteTable(edge:MarshalToTable())
		net.Send(self.Subscribers)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_Edge")

	---Sends a given triangle to all the subscribers.
	---@param triangle D3botNAV_TRIANGLE
	function NAV_PUBSUB:SendTriangleToSubs(triangle)
		if not self.Subscribers then return end

		net.Start("D3bot_Nav_PubSub_Triangle")
		net.WriteTable(triangle:MarshalToTable())
		net.Send(self.Subscribers)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_Triangle")

	---Sends a given air connection to all the subscribers.
	---@param airConnection D3botNAV_AIR_CONNECTION
	function NAV_PUBSUB:SendAirConnectionToSubs(airConnection)
		if not self.Subscribers then return end

		net.Start("D3bot_Nav_PubSub_AirConnection")
		net.WriteTable(airConnection:MarshalToTable())
		net.Send(self.Subscribers)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_AirConnection")

	---Deletes a given navmesh entity from all the subscribers.
	---@param id number | string
	function NAV_PUBSUB:DeleteByIDFromSubs(id)
		if not self.Subscribers then return end

		net.Start("D3bot_Nav_PubSub_Delete")
		net.WriteTable({id})
		net.Send(self.Subscribers)
	end
	util.AddNetworkString("D3bot_Nav_PubSub_Delete")
end

------------------------------------------------------
--		Client
------------------------------------------------------

if CLIENT then
	net.Receive("D3bot_Nav_PubSub_Navmesh",
		function(len)
			local navTableJSONCompressed = net.ReadData(net.ReadUInt(16))
			local navTableJSON = util.Decompress(navTableJSONCompressed)
			local navTable = util.JSONToTable(navTableJSON)
			local navmesh, err = NAV_MESH:NewFromTable(navTable)
			if err then print(string.format("%s Failed to recreate navmesh that the server sent: %s", D3bot.PrintPrefix, err)) end
			NAV_MAIN:SetNavmesh(navmesh)
		end
	)

	net.Receive("D3bot_Nav_PubSub_NavmeshDelete",
		function(len)
			NAV_MAIN:SetNavmesh(nil)
		end
	)

	net.Receive("D3bot_Nav_PubSub_Vertex",
		function(len)
			local navmesh = NAV_MAIN:GetNavmesh()
			local _, err = NAV_VERTEX:NewFromTable(navmesh, net.ReadTable())
			if err then print(string.format("%s Failed to recreate vertex that the server sent: %s", D3bot.PrintPrefix, err)) end
		end
	)

	net.Receive("D3bot_Nav_PubSub_Edge",
		function(len)
			local navmesh = NAV_MAIN:GetNavmesh()
			local _, err = NAV_EDGE:NewFromTable(navmesh, net.ReadTable())
			if err then print(string.format("%s Failed to recreate edge that the server sent: %s", D3bot.PrintPrefix, err)) end
		end
	)

	net.Receive("D3bot_Nav_PubSub_Triangle",
		function(len)
			local navmesh = NAV_MAIN:GetNavmesh()
			local _, err = NAV_TRIANGLE:NewFromTable(navmesh, net.ReadTable())
			if err then print(string.format("%s Failed to recreate triangle that the server sent: %s", D3bot.PrintPrefix, err)) end
		end
	)

	net.Receive("D3bot_Nav_PubSub_AirConnection",
		function(len)
			local navmesh = NAV_MAIN:GetNavmesh()
			local _, err = NAV_AIR_CONNECTION:NewFromTable(navmesh, net.ReadTable())
			if err then print(string.format("%s Failed to recreate air connection that the server sent: %s", D3bot.PrintPrefix, err)) end
		end
	)

	net.Receive("D3bot_Nav_PubSub_Delete",
		function(len)
			local navmesh = NAV_MAIN:GetNavmesh()
			local id = unpack(net.ReadTable())
			local entity = navmesh:FindByID(id)
			if entity then entity:Delete() end
		end
	)
end
