-- Copyright (C) 2020-2021 David Vogel
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

AddCSLuaFile()

------------------------------------------------------
--		Init
------------------------------------------------------

-- Init namespaces.
D3bot = D3bot or {}
D3bot.Version = {1, 0, 0} -- TODO: Create SemVer object or something.
D3bot.Config = D3bot.Config or {} -- General configuration table.
D3bot.Convars = D3bot.Convars or {} -- List of console variables.
D3bot.Util = D3bot.Util or {} -- Utility functions.
D3bot.Async = D3bot.Async or {} -- Async/coroutine utility functions.
D3bot.RenderUtil = D3bot.RenderUtil or {} -- Render helper/utility functions.
D3bot.MapGeometry = D3bot.MapGeometry or {} -- Functions for querying map geometry like corner points.
D3bot.ConCommands = D3bot.ConCommands or {} -- List of commands that can be run from the console.
D3bot.NavMain = D3bot.NavMain or {} -- Container for the main navmesh instance for both the server and client.
D3bot.NavFile = D3bot.NavFile or {} -- Navmesh file functions.
D3bot.NavPubSub = D3bot.NavPubSub or {} -- Navmesh pub/sub functions.
D3bot.NavEdit = D3bot.NavEdit or {} -- Functions to edit the main navmesh instance on the server. The functions are available on the client realm, too.
D3bot.Brains = D3bot.Brains or {} -- Brain handlers that run action handlers on bots.
D3bot.Actions = D3bot.Actions or {} -- Action handlers that represent bot behavior.
D3bot.LocomotionHandlers = D3bot.LocomotionHandlers or {} -- List of available locomotion handler classes that "link" navmesh geometry to bot behavior.

-- SWEP and UI namespaces.
D3bot.NavSWEP = D3bot.NavSWEP or {} -- Navmeshing SWEP stuff, this is not the SWEP table itself.
D3bot.NavSWEP.EditModes = D3bot.NavSWEP.EditModes or {} -- List of navmeshing edit modes.
D3bot.NavSWEP.UI = D3bot.NavSWEP.UI or {} -- General SWEP UI stuff.
D3bot.NavSWEP.UI.ReloadMenu = D3bot.NavSWEP.UI.ReloadMenu or {} -- RELOAD menu stuff.

-- Init default values.
D3bot.PrintPrefix = "D3bot:"
D3bot.HookPrefix = "D3bot_"
D3bot.VGUIPrefix = "D3bot_"
D3bot.AddonRoot = "d3bot/"

-- Init class namespaces.
D3bot.ERROR = D3bot.ERROR or {} -- Error handling/signalling class.
D3bot.PRIORITY_QUEUE = D3bot.PRIORITY_QUEUE or {} -- Prioritized queue class.
D3bot.CONCOMMAND = D3bot.CONCOMMAND or {} -- Console command class, to replicate and parse client side commands.
D3bot.NAV_MESH = D3bot.NAV_MESH or {} -- NAV_MESH class.
D3bot.NAV_VERTEX = D3bot.NAV_VERTEX or {} -- NAV_VERTEX class.
D3bot.NAV_EDGE = D3bot.NAV_EDGE or {} -- NAV_EDGE class.
D3bot.NAV_TRIANGLE = D3bot.NAV_TRIANGLE or {} -- NAV_TRIANGLE class.
D3bot.NAV_AIR_CONNECTION = D3bot.NAV_AIR_CONNECTION or {} -- NAV_AIR_CONNECTION class.
D3bot.PATH = D3bot.PATH or {} -- PATH class that handles pathfinding.
D3bot.PATH_POINT = D3bot.PATH_POINT or {} -- PATH_POINT helper class for start and destination points.

------------------------------------------------------
--		Includes
------------------------------------------------------

-- General stuff.
include("sh_util.lua")
local UTIL = D3bot.Util -- From here on UTIL.IncludeRealm can be used.
UTIL.IncludeRealm("", "sh_async.lua")
UTIL.IncludeRealm("", "sh_error.lua")
UTIL.IncludeRealm("", "sh_priority_queue.lua")
UTIL.IncludeRealm("", "sh_convars.lua")
UTIL.IncludeRealm("", "sv_control.lua")
UTIL.IncludeRealm("", "sv_ulx_fix.lua")
UTIL.IncludeRealm("", "sh_concommand.lua")
UTIL.IncludeRealm("", "sh_concommands.lua")
UTIL.IncludeRealm("", "sh_mapgeometry.lua")
UTIL.IncludeRealm("", "cl_renderutil.lua")

-- Navmesh stuff.
UTIL.IncludeRealm("navmesh/", "sh_main.lua")
UTIL.IncludeRealm("navmesh/", "sh_navmesh.lua")
UTIL.IncludeRealm("navmesh/", "sh_vertex.lua")
UTIL.IncludeRealm("navmesh/", "sh_edge.lua")
UTIL.IncludeRealm("navmesh/", "sh_triangle.lua")
UTIL.IncludeRealm("navmesh/", "sh_air_connection.lua")
UTIL.IncludeRealm("navmesh/", "sh_pubsub.lua")
UTIL.IncludeRealm("navmesh/", "sh_edit.lua")
UTIL.IncludeRealm("navmesh/", "sv_file.lua")

-- Path stuff.
UTIL.IncludeRealm("path/", "sh_path.lua")
UTIL.IncludeRealm("path/", "sh_path_point.lua")

-- Load bot naming script (default, and any optional override).
UTIL.IncludeRealm("names/", "sv_default.lua")
if D3bot.Config.NameScript then
	UTIL.IncludeRealm("names/", "sv_" .. D3bot.Config.NameScript .. ".lua")
end

-- Load any gamemode specific logic.
UTIL.IncludeRealm("gamemodes/" .. engine.ActiveGamemode() .. "/", "sh_init.lua")

-- Load locomotion handler classes (General and gamemode specific).
UTIL.IncludeDirectory(D3bot.AddonRoot .. "locomotion_handlers/", "*.lua")
UTIL.IncludeDirectory(D3bot.AddonRoot .. "gamemodes/" .. engine.ActiveGamemode() .. "/locomotion_handlers/", "*.lua")

-- Load action handlers (General and gamemode specific).
UTIL.IncludeDirectory(D3bot.AddonRoot .. "actions/", "*.lua")
UTIL.IncludeDirectory(D3bot.AddonRoot .. "gamemodes/" .. engine.ActiveGamemode() .. "/actions/", "*.lua")

-- Load brains (General and gamemode specific).
UTIL.IncludeDirectory(D3bot.AddonRoot .. "brains/", "*.lua")
UTIL.IncludeDirectory(D3bot.AddonRoot .. "gamemodes/" .. engine.ActiveGamemode() .. "/brains/", "*.lua")
