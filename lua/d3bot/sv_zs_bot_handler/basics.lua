D3bot.Basics = {}

function D3bot.Basics.SuicideOrRetarget(bot)
	local mem = bot.D3bot_Mem
	
	local nodeOrNil = mem.NodeOrNil
	local nextNodeOrNil = mem.NextNodeOrNil
	
	if nodeOrNil and nextNodeOrNil and nextNodeOrNil.Pos.z > nodeOrNil.Pos.z + 55 then
		local wallParam = nextNodeOrNil.Params.Wall
		if wallParam == "Retarget" then
			local handler = findHandler(bot:GetZombieClass(), bot:Team())
			if handler and handler.RerollTarget then handler.RerollTarget(bot) end
			return
		elseif wallParam == "Suicide" then
			bot:Kill()
			return
		end
	end
end

function D3bot.Basics.Walk(bot, pos, slowdown, proximity) -- 'pos' should be inside the current or next node.
	local mem = bot.D3bot_Mem
	
	local nodeOrNil = mem.NodeOrNil
	local nextNodeOrNil = mem.NextNodeOrNil
	
	local origin = bot:GetPos()
	local actions = {}
	local botMajorStuck = D3bot.IsBotStuck(bot)
	
	local sideSpeed
	
	-- Check if the bot needs to climb while being on a node or going towards a node. As maneuvering while climbing is different, this will change/override some movement actions.
	local shouldClimb = (nodeOrNil and nodeOrNil.Params.Climbing == "Needed") or (nextNodeOrNil and nextNodeOrNil.Params.Climbing == "Needed")
	
	-- Make bot aim straight when outside of current node area This should prevent falling down edges.
	local aimStraight
	if nodeOrNil and not nodeOrNil:GetContains(origin, nil) then aimStraight = true end
	if shouldClimb then
		if bot:GetActiveWeapon() and bot:GetActiveWeapon().GetClimbing and bot:GetActiveWeapon():GetClimbing() and bot:GetActiveWeapon().GetClimbSurface then
			local tr = bot:GetActiveWeapon():GetClimbSurface()
			if tr.Hit then
				bot:D3bot_FaceTo(origin - tr.HitNormal, origin, D3bot.BotAngLerpFactor, 0)
			end
		else
			bot:D3bot_FaceTo(Vector(pos.x, pos.y, origin.z), origin, 1, 0)
		end
	else
		bot:D3bot_FaceTo(pos, origin, aimStraight and 1 or D3bot.BotAngLerpFactor, aimStraight and 0 or 1)
	end
	
	local duckParam = nodeOrNil and nodeOrNil.Params.Duck
	local duckToParam = nextNodeOrNil and nextNodeOrNil.Params.DuckTo
	local jumpParam = nodeOrNil and nodeOrNil.Params.Jump
	local jumpToParam = nextNodeOrNil and nextNodeOrNil.Params.JumpTo
	
	-- Slow down bot when close to target (2D distance)
	local tempPos = Vector(pos.x, pos.y, origin.z)
	local invProximity = math.Clamp((origin:Distance(tempPos) - (proximity or 10))/60, 0, 1)
	local speed = bot:GetMaxSpeed() * (slowdown and invProximity or 1)
	
	-- Antistuck when bot is possibly stuck crouching below something
	if mem.AntiStuckTime and mem.AntiStuckTime > CurTime() then
		if not bot:Crouching() then
			mem.AntiStuckTime = nil
		else
			speed = -40
			actions.Jump = true
			actions.Attack = true
		end
	end

	local facesHindrance = not shouldClimb and bot:GetVelocity():Length2D() < 0.50 * speed - 10
	local minorStuck, majorStuck = bot:D3bot_CheckStuck()
	
	if not facesHindrance then
		mem.lastNoHindrance = CurTime()
	end
	
	if duckParam == "Always" or duckToParam == "Always" then
		actions.Duck = true
	end

	if botMajorStuck then
		actions.Jump = false
		actions.Duck = false
	elseif bot:GetMoveType() ~= MOVETYPE_LADDER then
		if bot:IsOnGround() then
			-- If we should climb, jump while we're on the ground
			if shouldClimb or jumpParam == "Always" or jumpToParam == "Always" then
				actions.Jump = true
			end
			if facesHindrance then
				if math.random(D3bot.BotJumpAntichance) == 1 then
					actions.Jump = true
				end
				if math.random(D3bot.BotDuckAntichance) == 1 then
					actions.Duck = true
				end
				-- Check if bot is possibly stuck below something
				if bot:Crouching() and not actions.Duck and (not bot.D3bot_LastDamage or bot.D3bot_LastDamage < CurTime() - 2) and (not mem.lastNoHindrance or mem.lastNoHindrance < CurTime() - 2) then
					mem.AntiStuckTime = CurTime() + 1
				end
			end
		else
			actions.Duck = true
			if shouldClimb then
				-- If we are airborne and should be climbing, try to climb the surface
				actions.Attack2 = true
				-- Calculate climbing speeds
				if bot:GetActiveWeapon() and bot:GetActiveWeapon().GetClimbing and bot:GetActiveWeapon():GetClimbing() then
					local yaw1 = bot:GetForward():Angle().Yaw
					local yaw2 = (Vector(pos.x, pos.y, origin.z) - origin):Angle().Yaw
					sideSpeed = math.AngleDifference(yaw1, yaw2)
					speed = (pos.z - origin.z + 20) * 10
					if (math.abs(speed) < 20 or bot:GetVelocity():Length() < 10) and math.abs(sideSpeed) > 1 then speed = 0 end
				end
			end
		end
	elseif minorStuck then
		-- Stuck on ladder
		actions.Jump = true
		actions.Duck = true
		actions.Use = true
	end
	
	if duckParam == "Disabled" or duckToParam == "Disabled" then
		actions.Duck = false
	end
	if math.random(1, 2) == 1 or jumpParam == "Disabled" or jumpToParam == "Disabled" or (not actions.Duck and bot:Crouching()) then
		actions.Jump = false
	end
	
	actions.Attack = facesHindrance
	actions.Use = actions.Use or facesHindrance
	if not botMajorStuck then
		if speed > 0 then actions.MoveForward = true end
		if speed < 0 then actions.MoveBackward = true end
		
		if sideSpeed and sideSpeed > 0 then actions.MoveRight = true end
		if sideSpeed and sideSpeed < 0 then actions.MoveLeft = true end
	else
		actions.MoveForward = false
		actions.MoveBackward = false
		actions.MoveRight = false
		actions.MoveLeft = false
		speed = 0
	end
	return true, actions, speed, sideSpeed, nil, mem.Angs, minorStuck, majorStuck, facesHindrance
end

function D3bot.Basics.WalkAttackAuto(bot)
	local mem = bot.D3bot_Mem
	if not mem then return end
	
	local nodeOrNil = mem.NodeOrNil
	local nextNodeOrNil = mem.NextNodeOrNil
	local botMajorStuck = D3bot.IsBotStuck(bot)

	local aimPos, origin
	local actions = {}
	local facesTgt = false
	
	-- Check if the bot needs to climb while being on a node or going towards a node. If so, ignore everything else, and use Basics.WalkAuto, which will handle everything fine. TODO: Put everything into its own basics function
	local shouldClimb = (nodeOrNil and nodeOrNil.Params.Climbing == "Needed") or (nextNodeOrNil and nextNodeOrNil.Params.Climbing == "Needed")
	
	-- TODO: Reduce can see target calls
	if shouldClimb and nextNodeOrNil then
		return D3bot.Basics.Walk(bot, nextNodeOrNil.Pos)
	elseif mem.TgtOrNil and not mem.DontAttackTgt and (bot:D3bot_CanSeeTargetCached() or not nextNodeOrNil) then
		aimPos = bot:D3bot_GetAttackPosOrNilFuture(nil, math.Rand(0, D3bot.BotAimPosVelocityOffshoot))
		origin = bot:D3bot_GetViewCenter()
		if aimPos and aimPos:DistToSqr(origin) < math.pow(D3bot.BotAttackDistMin, 2) then
			if weapon and weapon.MeleeReach then
				local tr = util.TraceLine({
					start = origin,
					endpos = origin + bot:EyeAngles():Forward() * weapon.MeleeReach,
					filter = bot
				})
				facesTgt = tr.Entity == mem.TgtOrNil
			else
				facesTgt = true
			end
			if aimPos.z < bot:GetPos().z + bot:GetViewOffsetDucked().z then
				actions.Duck = true
			end
		end
	elseif mem.PosTgtOrNil and not nextNodeOrNil then
		-- Go straight to position target
		return D3bot.Basics.Walk(bot, mem.PosTgtOrNil, true, mem.PosTgtProximity)
	elseif nextNodeOrNil then
		-- Target not visible, walk towards next node
		return D3bot.Basics.Walk(bot, nextNodeOrNil.Pos)
	elseif mem.TgtOrNil then
		-- There is a target entity, but the bot shouldn't attack it
		return D3bot.Basics.Walk(bot, mem.TgtOrNil:GetPos(), true, mem.TgtProximity)
	else
		return
	end
	
	if aimPos then
		bot:D3bot_FaceTo(aimPos, origin, D3bot.BotAttackAngLerpFactor, facesTgt and D3bot.FaceTargetOffshootFactor or 1)
	end
	
	local duckParam = nodeOrNil and nodeOrNil.Params.Duck
	local duckToParam = nextNodeOrNil and nextNodeOrNil.Params.DuckTo
	local jumpParam = nodeOrNil and nodeOrNil.Params.Jump
	local jumpToParam = nextNodeOrNil and nextNodeOrNil.Params.JumpTo
	
	local speed = bot:GetMaxSpeed()
	
	-- Antistuck when bot is possibly stuck crouching below something
	if mem.AntiStuckTime and mem.AntiStuckTime > CurTime() then
		if not bot:Crouching() then
			mem.AntiStuckTime = nil
		else
			speed = -40
			actions.Jump = true
			actions.Attack = true
		end
	end

	local facesHindrance = bot:GetVelocity():Length2D() < 0.50 * speed - 10
	local minorStuck, majorStuck = bot:D3bot_CheckStuck()
	
	if not facesHindrance then
		mem.lastNoHindrance = CurTime()
	end
	
	if duckParam == "Always" or duckToParam == "Always" then
		actions.Duck = true
	end
	
	if bot:GetMoveType() ~= MOVETYPE_LADDER and not botMajorStuck then
		if bot:IsOnGround() then
			if jumpParam == "Always" or jumpToParam == "Always" then
				actions.Jump = true
			end
			if facesHindrance then
				if math.random(D3bot.BotJumpAntichance) == 1 then
					actions.Jump = true
				end
				if math.random(D3bot.BotDuckAntichance) == 1 then
					actions.Duck = true
				end
				-- Check if bot is possibly stuck below something
				if bot:Crouching() and not actions.Duck and (not bot.D3bot_LastDamage or bot.D3bot_LastDamage < CurTime() - 2) and (not mem.lastNoHindrance or mem.lastNoHindrance < CurTime() - 2) then
					mem.AntiStuckTime = CurTime() + 1
				end
			end
		else
			actions.Duck = true
		end
	elseif botMajorStuck then
		actions.Jump = false
		actions.Duck = false
		actions.Use = false
	elseif minorStuck then
		-- Stuck on ladder
		actions.Jump = true
		actions.Duck = true
		actions.Use = true
	end
	
	if duckParam == "Disabled" or duckToParam == "Disabled" then
		actions.Duck = false
	end
	if math.random(1, 2) == 1 or jumpParam == "Disabled" or jumpToParam == "Disabled" or (not actions.Duck and bot:Crouching()) then
		actions.Jump = false
	end
	
	actions.Attack = facesTgt or facesHindrance
	actions.Use = actions.Use or facesHindrance
	
	actions.MoveForward = not botMajorStuck
	
	return true, actions, speed, nil, nil, mem.Angs, minorStuck, majorStuck, facesHindrance
end

function D3bot.Basics.PounceAuto(bot)
	local mem = bot.D3bot_Mem
	if not mem then return end
	
	if not bot:IsOnGround() or bot:GetMoveType() == MOVETYPE_LADDER then return end
	
	local weapon = bot:GetActiveWeapon()
	if not weapon and not weapon.PounceVelocity then return end
	
	-- Fill table with possible pounce target positions, ordered with increasing priority
	local tempPos = bot:GetPos()
	local tempDist = 0
	local pounceTargetPositions = {}
	if nextNodeOrNil then
		tempDist = tempDist + tempPos:Distance(nextNodeOrNil.Pos)
		tempPos = nextNodeOrNil.Pos
		table.insert(pounceTargetPositions, {Pos = nextNodeOrNil.Pos + Vector(0, 0, 1),
											 Dist = tempDist,
											 TimeFactor = 1.1,
											 ForcePounce = (nextNodeOrNil.LinkByLinkedNode[nodeOrNil] and nextNodeOrNil.LinkByLinkedNode[nodeOrNil].Params.Pouncing == "Needed")})
	end
	local i = 0
	for k, v in ipairs(mem.RemainingNodes) do -- TODO: Check if it behaves as expected
		tempDist = tempDist + tempPos:Distance(v.Pos)
		tempPos = v.Pos
		table.insert(pounceTargetPositions, {Pos = v.Pos + Vector(0, 0, 1), Dist = tempDist, TimeFactor = 1.1})
		i = i + 1
		if i == 2 then break end
	end
	local tempAttackPosOrNil = bot:D3bot_GetAttackPosOrNilFuturePlatforms(0, mem.pounceFlightTime or 0)
	if tempAttackPosOrNil then
		tempDist = tempDist + bot:GetPos():Distance(tempAttackPosOrNil)
		table.insert(pounceTargetPositions, {Pos = tempAttackPosOrNil + Vector(0, 0, 1), Dist = tempDist, TimeFactor = 0.8, HeightDiff = 100}) -- TODO: Global bot 'IQ' level influences TimeFactor, the lower the more likely they will cut off the players path
	elseif mem.PosTgtOrNil then
		tempDist = tempDist + bot:GetPos():Distance(mem.PosTgtOrNil)
		table.insert(pounceTargetPositions, {Pos = mem.PosTgtOrNil + Vector(0, 0, 1), Dist = tempDist, TimeFactor = 0.8, HeightDiff = 100})
	end
	
	-- Find best trajectory
	local trajectory
	for _, pounceTargetPos in ipairs(table.Reverse(pounceTargetPositions)) do
		local trajectories = bot:D3bot_CanPounceToPos(pounceTargetPos.Pos)
		local timeToTarget = pounceTargetPos.Dist / bot:GetMaxSpeed()
		if trajectories and (pounceTargetPos.ForcePounce or (pounceTargetPos.HeightDiff and pounceTargetPos.Pos.z - bot:GetPos().z > pounceTargetPos.HeightDiff) or timeToTarget > (trajectories[1].t1 + weapon.PounceStartDelay)*pounceTargetPos.TimeFactor) then
			trajectory = trajectories[1]
			break
		end
	end
	
	local actions = {}
	
	if (trajectory and CurTime() >= weapon:GetNextPrimaryFire() and CurTime() >= weapon:GetNextSecondaryFire() and CurTime() >= weapon.NextAllowPounce) or mem.pouncing then
		if trajectory then
			mem.Angs = Angle(-math.deg(trajectory.pitch), math.deg(trajectory.yaw), 0)
			mem.pounceFlightTime = math.Clamp(trajectory.t1 + (mem.pouncingStartTime or CurTime()) - CurTime(), 0, 1) -- Store flight time, and use it to iteratively get close to the correct intersection point.
		end
		if not mem.pouncing then
			-- Started pouncing
			actions.Attack2 = true
			mem.pouncingTimer = CurTime() + 0.9 + math.random() * 0.2
			mem.pouncingStartTime = CurTime() + weapon.PounceStartDelay
			mem.pouncing = true
		elseif mem.pouncingTimer and mem.pouncingTimer < CurTime() and (CurTime() - mem.pouncingTimer > 5 or bot:WaterLevel() >= 2 or bot:IsOnGround()) then
			-- Ended pouncing
			mem.pouncing = false
			mem.pounceFlightTime = nil
			bot:D3bot_UpdatePathProgress()
		end
		
		return true, actions, 0, nil, nil, mem.Angs, false
	end
	
	return
end

function D3bot.Basics.AimAndShoot(bot, target, maxDistance)
	local mem = bot.D3bot_Mem
	if not mem then return end
	
	local actions = {}
	local reloading
	
	if not IsValid(target) then return end
	local weapon = bot:GetActiveWeapon()
	if not IsValid(weapon) then return end
	if weapon:Clip1() == 0 then reloading = true end
	if (weapon.GetNextReload and weapon:GetNextReload() or 0) > CurTime() - 0.5 then -- Subtract half a second, so it will re-trigger reloading if possible
		reloading = true
	end
	actions.Reload = reloading and math.random(5) == 1
	
	local origin = bot:D3bot_GetViewCenter()
	local targetPos = LerpVector(mem.AimHeightFactor or 1, target:GetPos(), target:EyePos())
	
	if maxDistance and origin:DistToSqr(targetPos) > math.pow(maxDistance, 2) then return end
	
	-- TODO: Use fewer traces, cache result for a few frames.
	local tr = util.TraceLine({
		start = origin,
		endpos = targetPos,
		filter = player.GetAll(),
		mask = MASK_SHOT_HULL
	})
	local canShootTarget = not tr.Hit
	
	if not canShootTarget then mem.AimHeightFactor = math.Rand(0.5, 1) end
	
	actions.Attack = not reloading and bot:D3bot_IsLookingAt(targetPos, 0.8) and canShootTarget and not mem.WasPressingAttack
	mem.WasPressingAttack = actions.Attack
	
	if targetPos and canShootTarget then
		bot:D3bot_FaceTo(targetPos, origin, D3bot.BotAimAngLerpFactor, 0)
	end
	
	return true, actions, 0, nil, nil, mem.Angs, false
end

function D3bot.Basics.LookAround(bot)
	local mem = bot.D3bot_Mem
	if not mem then return end

	if math.random(200) == 1 then mem.LookTarget = table.Random(player.GetAll()) end
	
	if not IsValid(mem.LookTarget) then return end
	
	local origin = bot:D3bot_GetViewCenter()
	
	bot:D3bot_FaceTo(mem.LookTarget:D3bot_GetViewCenter(), origin, D3bot.BotAngLerpFactor * 0.3, 0)
	
	return true, nil, 0, nil, nil, mem.Angs, false
end
