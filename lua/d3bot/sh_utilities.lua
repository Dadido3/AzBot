function D3bot.GetTrajectories2DParams(g, initVel, distZ, distRad)
	local trajectories = {}
	local radix = initVel^4 - g*(g*distRad^2 + 2*distZ*initVel^2)
	
	if radix < 0 then return trajectories end
	local pitch = math.atan((initVel^2 - math.sqrt(radix)) / (g*distRad))
	local t1 = distRad / (initVel * math.cos(pitch))
	table.insert(trajectories, {g = g, initVel = initVel, pitch = pitch, t1 = t1})
	if radix > 0 then
		local pitch = math.atan((initVel^2 + math.sqrt(radix)) / (g*distRad))
		local t1 = distRad / (initVel * math.cos(pitch))
		table.insert(trajectories, {g = g, initVel = initVel, pitch = pitch, t1 = t1})
	end
	
	return trajectories
end

function D3bot.IsBotStuck(bot) 
	local botPos = bot:GetPos()
	local tracedata = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
	tracedata.start = bot:GetPos()
	tracedata.endpos = tracedata.start
	tracedata.filter = bot
	local traceResult = util.TraceEntity(tracedata,bot)
	return bot:Alive() and traceResult and traceResult.StartSolid == true and not traceResult.Entity:IsWorld() and (traceResult.Entity:IsValid() and traceResult.Entity:GetClass() == "prop_physics") and traceResult.Entity:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS and traceResult.Entity:IsNailed()
end

function D3bot.GetTrajectory2DPoints(trajectory, segments)
	trajectory.points = {}
	for i = 0, segments, 1 do
		local t = Lerp(i/segments, 0, trajectory.t1)
		local r = Vector(math.cos(trajectory.pitch)*trajectory.initVel*t, 0, math.sin(trajectory.pitch)*trajectory.initVel*t - trajectory.g/2*t^2)
		table.insert(trajectory.points, r)
	end
	
	return trajectory
end

function D3bot.GetTrajectories(initVel, r0, r1, segments)
	local g = 600 -- Hard coded acceleration, should be read from gmod later
	
	local distZ = r1.z - r0.z
	local distRad = math.sqrt((r1.x - r0.x)^2 + (r1.y - r0.y)^2)
	local yaw = math.atan2(r1.y - r0.y, r1.x - r0.x)
	
	local trajectories = D3bot.GetTrajectories2DParams(g, initVel, distZ, distRad)
	for i, trajectory in ipairs(trajectories) do
		trajectories[i].yaw = yaw
		-- Calculate 2D trajectory from parameters
		trajectories[i] = D3bot.GetTrajectory2DPoints(trajectory, segments)
		-- Rotate and move trajectory into 3D space
		for k, _ in ipairs(trajectory.points) do
			trajectory.points[k]:Rotate(Angle(0, math.deg(yaw), 0))
			trajectory.points[k]:Add(r0)
		end
	end
	
	return trajectories
end

-- Remove spectating, meshing and dead players
function D3bot.RemoveObsDeadTgts(tgts)
	return D3bot.From(tgts):Where(function(k, v) return IsValid(v) and v:GetObserverMode() == OBS_MODE_NONE and not v:IsFlagSet(FL_NOTARGET) and v:Alive() end).R
end

function D3bot.NeighbourNodeFalloff(startNode, iterations, startValue, falloff, nodes)
	if not startNode then return end
	local nodes = nodes or {}
	local queue = {startNode}
	nodes[startNode] = (nodes[startNode] or 0) + startValue
	while #queue > 0 and iterations > 0 do
		local node = table.remove(queue)
		iterations = iterations - 1
		for linkedNode, link in pairs(node.LinkByLinkedNode) do
			nodes[linkedNode] = nodes[node] * falloff
			table.insert(queue, linkedNode)
		end
	end
	return nodes
end

function D3bot.GetBots() -- Return all players controlled by this script (Can also be real players)
	local bots = {}
	for _, v in pairs(player.GetAll()) do
		if v.D3bot_Mem then
			table.insert(bots, v)
		end
	end
	return bots
end
