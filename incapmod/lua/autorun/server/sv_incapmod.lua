----[[ Code ----]]
-- Library initialization
do
	local Player = FindMetaTable( "Player" )
	local offset = Vector( 0, 0, -29 )
	local rotation = Angle( 0, 0, -90 )
	--[[ Function Player:Incap()
		arguments: none
		return values: none
	Incapaciates player function is called on --]]
	function Player:Incap()
		if not IncapMod.Enabled:GetBool() then return end
		if self:IsIncapaciated() then return end
		hook.Run( "OnPlayerIncapaciated", self )
		self.MaxHealth = self:GetMaxHealth()
		self:SetHealth( hook.Run( "PlayerIncappedHealth", self ) or IncapMod.IncapHealth:GetFloat() )
		self:SetNWFloat( "MaxIncappedHealth", self:Health() )
		self:SetMaxHealth( 0 )
		self:SetNWBool( "IsIncapped", true )
		if IsValid( self:GetCurrentlyRescuedPlayer() ) then
			self:GetCurrentlyRescuedPlayer():ClearRescue()
		end
		IncapMod.IncappedPlayers[ self ] = true
		self:Flashlight( false )
		self.FlashlightAllowed = self:CanUseFlashlight()
		self:AllowFlashlight( false )
		self.nextDmg = CurTime() + 1
		if not IncapMod.AllowedWeapons[ self:GetActiveWeapon():GetClass() ] then
			for wep, _ in pairs( IncapMod.AllowedWeapons ) do
				if self:HasWeapon( wep ) then
					self.NextSelectWeapon = wep
					break
				end
			end
		end
		self:ManipulateBonePosition( 0, offset )
		self:ManipulateBoneAngles( 0, rotation )
		--[[ W.I.P
		if not IncapMod.ChatScream:GetBool() then return end
		if math.random( 1, IncapMod.ScreamChance:GetInt() ) ~= 1 then return end
		self:Say( ( ( IsValid( self.attacker ) and math.random( 1, 2 ) == 1 ) and
			( IncapMod.Phrases.Incapaciation.ByPlayer[ math.random( 1, #IncapMod.Phrases.Incapaciation.ByPlayer ) ] ):format( self.attacker:Nick() ) ) or 
			IncapMod.Phrases.Incapaciation.Generic[ math.random( 1, #IncapMod.Phrases.Incapaciation.Generic ) ], 
			IncapMod.TeamChatOnly:GetBool()
		) --]]
	end
	--[[ Function Player:UnIncap()
		arguments: none
		return values: none
	Un-incapaciates player function is called on --]]
	function Player:UnIncap()
		if not IncapMod.Enabled:GetBool() then return end
		if not self:IsIncapaciated() then return end
		self:SetNWBool( "IsIncapped", false )
		self:ManipulateBonePosition( 0, vector_origin )
		self:ManipulateBoneAngles( 0, angle_zero )
		--[[ W.I.P
		if IncapMod.ChatScream:GetBool() and math.random( 1, IncapMod.ScreamChance:GetInt() ) == 1 then
			self:Say( ( ( IsValid( self:GetRescuedBy() ) and math.random( 1, 2 ) == 1 ) and
				( IncapMod.Phrases.Rescue.ByPlayer[ math.random( 1, #IncapMod.Phrases.Rescue.ByPlayer ) ] ):format( self:GetRescuedBy():Nick() ) ) or 
				IncapMod.Phrases.Rescue.Generic[ math.random( 1, #IncapMod.Phrases.Rescue.Generic ) ], 
				IncapMod.TeamChatOnly:GetBool()
			)
		end --]]
		local rescuer = self:GetRescuedBy()
		self:ClearRescue()
		self:SetMaxHealth( self.MaxHealth )
		self:SetHealth( hook.Run( "PlayerHealthRestoreOnUnincap", self, rescuer ) or self.MaxHealth * IncapMod.RestorePortion:GetFloat() )
		self.MaxHealth = nil
		self:SetNWFloat( "MaxIncappedHealth", 0 )
		IncapMod.IncappedPlayers[ self ] = nil
		self:AllowFlashlight( self.FlashlightAllowed )
		self.FlashlightAllowed = nil
		self.nextDmg = nil
		self.attacker = nil
	end
	--[[ Function Player:ClearRescue()
		arguments: none
		return values: none
	If someone is rescuing this player, rescue will be stopped --]]
	function Player:ClearRescue()
		if not IncapMod.Enabled:GetBool() then return end
		if not self:IsIncapaciated() then return end
		if IsValid( self:GetRescuedBy() ) then
			self:GetRescuedBy():SetNWEntity( "PlayerRescuing", NULL )
		end
		self:SetRescueTimer( 0, 0 )
		self:SetNWEntity( "RescuingPlayer", NULL )
	end
	--[[ Function Player:SetRescue()
		arguments: (Player) player to start rescue by
		return values: none
	Initiate a rescue of this player by pointed player --]]
	function Player:SetRescue( ply )
		if not IncapMod.Enabled:GetBool() then return end
		if not self:IsIncapaciated() then return end
		if hook.Run( "PlayerBlockRescue", ply, self ) then return end
		self:SetNWEntity( "RescuingPlayer", ply )
		self:StartRescueTimer( 0, hook.Run( "PlayerRescueRequiredTime", self, ply, false ) or IncapMod.PlayerRescueDefaultTime:GetFloat() )
		ply:SetNWEntity( "PlayerRescuing", self )
	end
	--[[ Function Player:SetRescueTimer()
	arguments: (number) starttime - start time relative to CurTime; (number) endtime - end time relative to CurTime
	return values: none
	Sets rescue timer directly --]]
	function Player:SetRescueTimer( starttime, endtime )
		if not self:IsIncapaciated() then return end
		self:SetNWFloat( "RescueStartTime", starttime )
		self:SetNWFloat( "RescueEndTime", endtime )
	end
	--[[ Function Player:AdvanceRescueTimer()
	arguments: (number) starttime - timer start adjustment; (number) endtime - timer end adjustment
	return values: none
	"Offsets" rescue timer --]]
	function Player:AdvanceRescueTimer( starttime, endtime )
		if not self:IsIncapaciated() then return end
		self:SetNWFloat( "RescueStartTime", self:GetNWFloat( "RescueStartTime", 0 ) + starttime )
		self:SetNWFloat( "RescueEndTime", self:GetNWFloat( "RescueEndTime", 0 ) + endttime )
	end
	--[[ Function Player:StartRescueTimer()
	arguments: (number) startoffset - timer start offset; (number) duration - timer duration
	return values: none
	Sets player's rescue timer, where start is CurTime() + startoffset and end is CurTime() + duration --]]
	function Player:StartRescueTimer( startoffset, duration )
		self:SetNWFloat( "RescueStartTime", CurTime() + startoffset )
		self:SetNWFloat( "RescueEndTime", CurTime() + duration )
	end
	--[[ Function Player:GiveStandUps()
	arguments: (number) amount - amount of "Stand-Ups" to increase by
	return values: none
	Increases player's "Stand-Ups" --]]
	function Player:GiveStandUps( amount )
		self:SetNWInt( "StandUpsLeft", self:GetNWInt( "StandUpsLeft", 0 ) + math.Round( amount ) )
	end
	--[[ Function Player:SetStandUps()
	arguments: (number) amount - amount of "Stand-Ups" to set to
	return values: none
	Sets player's "Stand-Ups" --]]
	function Player:SetStandUps( amount )
		self:SetNWInt( "StandUpsLeft", math.Round( amount ) )
	end
end

-- Hook run every time something takes damage
hook.Add( "EntityTakeDamage", "ModifyIncapDamage", function( target, dmginfo )
	if not IncapMod.Enabled:GetBool() then return end
	if not target:IsPlayer() then return end -- Discards execution of the code below if target is not player
	if target:IsIncapaciated() then return end -- Checks if not incapped
	if target:Health() - dmginfo:GetDamage() > 0 then return end -- Discards if player isn't going to be dead after damage
	if hook.Run( "PlayerBlockIncapaciation", target, dmginfo:GetAttacker(), dmginfo:GetDamage(), dmginfo:GetInflictor() ) then return end -- Player will die if "PlayerBlockIncapaciation" returns true
	target:Incap() -- Incaps player
	target.attacker = dmginfo:GetAttacker() -- Sets the incapaciator. Optional
	if bit.band( IncapMod.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTINCAP" ] ) <= 0 then return true end
	print( "Player " .. target:Nick() .. " has been incapaciated" ) -- Prints into console
	return true -- Blocks fatal damage
end )

hook.Add( "PostEntityTakeDamage", "identifier", function( ent, dmginfo, took )
	if not IncapMod.Enabled:GetBool() then return end
	if not ent:IsPlayer() then return end
	if not ent:IsIncapaciated() then return end
	if not IsValid( ent:GetRescuedBy() ) then return end
	if not hook.Run( "ShouldResetRescueOnDamage", ent, ent:GetRescuedBy(), dmginfo, took ) and dmginfo:GetDamage() < IncapMod.RescueDamageResetThreshold:GetFloat() then return end
	ent:StartRescueTimer( 0, ( hook.Run( "PlayerRescueRequiredTime", ent, ent:GetRescuedBy(), true ) or IncapMod.PlayerRescueDefaultTime:GetFloat() ) )
end )

-- Just initializes all variables
hook.Add( "PlayerInitialSpawn", "InitPly", function( ply, trs )
	ply:SetNWBool( "IsIncapped", false )
	ply:SetRescueTimer( 0, 0 )
	ply:ClearRescue()
	ply:SetStandUps( hook.Run( "GrantPlayerStandUps", ply ) or IncapMod.StartingStandUps:GetInt() )
	ply.nextDmg = 0
end )

-- Hook that runs every time player is dead
hook.Add( "PlayerDeath", "RestoreIncap", function( ply, inf, att )
	-- Unincappes players on their death so effect won't stay after
	timer.Simple( 0, function()
		ply:UnIncap()
		ply:SetStandUps( hook.Run( "GrantPlayerStandUps", ply ) or IncapMod.StartingStandUps:GetInt() ) -- Resets amount of "Stand-Ups" player have
	end )
end )

-- Same as above, but when player is killed silently
hook.Add( "PlayerDeathSilent", "RestoreIncap", function( ply )
	-- Same, but for silent death
	ply:UnIncap()
	ply:SetStandUps( hook.Run( "GrantPlayerStandUps", ply ) or IncapMod.StartingStandUps:GetInt() )
end )

-- Runs every tick
hook.Add( "Think", "DamageIncappedOnes", function()
	if not IncapMod.Enabled:GetBool() then return end
	for ply, _ in pairs( IncapMod.IncappedPlayers ) do
		if not ( CurTime() >= ply:GetNWFloat( "RescueEndTime", 0 ) and ply:GetNWFloat( "RescueStartTime", 0 ) ~= 0 and IsValid( ply:GetNWEntity( "RescuingPlayer", nil ) ) ) then
			if not ply:IsIncapaciated() then continue end -- Discards if player is not incapaciated
			if CurTime() < ply.nextDmg or IsValid( ply:GetRescuedBy() ) then continue end -- Discards if cooldown on damage hasn't pass or player has a rescuer
			ply.nextDmg = CurTime() + 1 -- Sets cooldown
			local damage = hook.Run( "PlayerBleed", ply ) or IncapMod.Bleedout:GetInt()
			if ply:Health() <= damage then
				-- "Kills" player if he's out of health
				local dmgInfo = DamageInfo()
				dmgInfo:SetAttacker( ply.attacker or game.GetWorld() )
				dmgInfo:SetDamage( ply:Health() ) -- Builds "Damage data"
				ply:SetArmor( 0 ) -- Sets armor to 0 so it doesn't consume damage
				ply:TakeDamageInfo( dmgInfo ) -- Damages player so it kills them
				if bit.band( IncapMod.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTBLEEDOUT" ] ) <= 0 then return end -- Don't run if printing of bleeding out is disabled
				print( "Player " .. ply:Nick() .. " lost " .. tostring( dmgInfo:GetDamage() ) .. " liters of blood and died due to bloodloss " ) -- Prints to console when player died due to bloodloss
			else
				ply:SetHealth( ply:Health() - damage ) -- Decreases player's health
				if bit.band( IncapMod.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTBLEEDING" ] ) <= 0 then return end -- Checks if printing of bleeding is disabled
				print( "Player " .. ply:Nick() .. " lost " .. damage .. " liters of blood" ) -- Prints to console when player is bleeding
			end
		else
			if bit.band( IncapMod.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTRESCUE" ] ) > 0 then -- Checks if printing of rescuing is disabled
				print( "Player " .. ply:Nick() .. " has been rescued by " .. ply:GetRescuedBy():Nick() ) -- Prints to console when player is rescued
			end
			hook.Run( "OnPlayerRescued", ply, ply:GetRescuedBy() )
			ply:UnIncap() -- Un-incapaciates player
		end
	end
end )

-- Hook that affects player's inputs
hook.Add( "StartCommand", "RestrictPlayerMovementWhileIncapaciatedAndRescuing", function( ply, cmd )
	ply.result_speed = hook.Run( "PlayerIncappedSpeed", ply ) or IncapMod.MoveSpeed:GetFloat() -- Caches max speed to not call hook twice
	if ply:IsIncapaciated() then
		cmd:RemoveKey( IN_DUCK )-- Forces player to uncrouch while incapped
		if ply.NextSelectWeapon then -- If player is holding disallowed weapon, changes it to allowed one
			cmd:SelectWeapon( ply:GetWeapon( ply.NextSelectWeapon )	)
			ply.NextSelectWeapon = nil
		end
		if ply:StandUpsLeft() <= 0 then -- Manages times when player has some "Stand-Ups" left
			cmd:RemoveKey( IN_JUMP ) -- Disallows jumping if player has no "Stand-Ups"
		elseif cmd:KeyDown( IN_JUMP ) then
			ply:UnIncap()
			ply:GiveStandUps( -1 )
			cmd:RemoveKey( IN_JUMP ) -- If player has at least 1 "Stand-Up", decreases amount of it and un-incapaciates player
		end
		if ply.result_speed <= 0 or ( not IncapMod.MoveWhenRescued:GetBool() and IsValid( ply:GetRescuedBy() ) ) then
			cmd:ClearMovement() -- Blocks movement when max incapped speed is 0 or below or player is being rescued
		end
	-- Rescue stuff
	elseif cmd:KeyDown( IN_USE ) and IsValid( ply:GetCurrentlyRescuedPlayer() ) and ply:GetCurrentlyRescuedPlayer() ~= ply then -- Checks if player is holding use key and is rescuing someone
		if ply:GetEyeTraceNoCursor().Entity ~= ply:GetCurrentlyRescuedPlayer() or ply:GetEyeTraceNoCursor().Entity:GetPos():DistToSqr( ply:GetPos() ) > IncapMod.MaxRescueDist:GetInt() ^ 2 or not ply:GetCurrentlyRescuedPlayer():IsIncapaciated() or ply:IsIncapaciated() then -- Interrupts rescue if rescuer is not looking at rescuant anymore, too far, rescuant became non-incapaciated or rescuer was incapaciated
			ply:GetCurrentlyRescuedPlayer():ClearRescue()
			return
		else
			cmd:SetButtons( IN_USE )
			cmd:ClearMovement() -- Blocks rescuer from moving while rescuing
		end
	elseif IsValid( ply:GetCurrentlyRescuedPlayer() ) and not cmd:KeyDown( IN_USE ) then -- Interrupts rescue if rescuer doesn't hold use key anymore
		ply:GetCurrentlyRescuedPlayer():ClearRescue()
	elseif not IsValid( ply:GetCurrentlyRescuedPlayer() ) and cmd:KeyDown( IN_USE ) then -- Looks if currently isn't rescuing anyone and is holding a use key
		if ply:IsIncapaciated() then return end -- Blocks incapaciated players from rescuing other players
		if not ply:GetEyeTraceNoCursor().Entity:IsPlayer() then return end -- Blocks from rescuing anything else other than player
		if not ply:GetEyeTraceNoCursor().Entity:IsIncapaciated() then return end -- Blocks from rescuing non-incapaciated players
		if ply:GetEyeTraceNoCursor().Entity:GetPos():DistToSqr( ply:GetPos() ) > IncapMod.MaxRescueDist:GetInt() ^ 2 then return end
		if hook.Run( "PlayerBlockRescue", ply, ply:GetEyeTraceNoCursor().Entity ) then return end -- Blocks resue if "PlayerBlockRescue" return true
		if ply:Team() ~= ply:GetEyeTraceNoCursor().Entity:Team() and IncapMod.OnlyTeammates:GetBool() then return end -- If "incapmod_rescueteammatesonly" is set to 1, blocks rescue if players are from different teams
		ply:GetEyeTraceNoCursor().Entity:SetRescue( ply ) -- Starts rescue
	end
end )

hook.Add( "SetupMove", "RestrictPlayerMove", function( ply, mv, cmd ) -- Also restricts movement. Required in case if player can move while incapped
	if not ply:IsIncapaciated() then return end -- Doesn't run if player is not incapaciated
	if ply.result_speed <= 0 then return end -- Doesn't run if max player speed while incapped is 0 or below
	mv:SetMaxClientSpeed( ply.result_speed ) -- Restricts speed to max speed
end )

----[[ Interfaces ----]]
-- These are gradients that are shown on player's screen when he is incapaciated
-- If you have overriden "DrawPlayerOnIncap" hook, and it doesn't include these, you can delete it
resource.AddFile( "materials/sprites/grad-incap.png" )
resource.AddFile( "materials/sprites/grad-incap-pain.png" )
resource.AddFile( "materials/sprites/death-skull.png" )

-- These hooks are for customization purposes. You can override them and even delete them (in which case value is reset to default one)

--[[ Hook "PlayerShouldBeIncapaciated"
	arguments: (Player) ply - player that is about to be incapaciated; (Entity) att - entity that incapaciated player; (CTakeDamageInfo) dmg - damage info of the final blow; (Entity) inf - inflictor of the damage
	return values: (bool) allow - determines if player should be incapaciated. If not returned "false" or "nil", player will die instead of being incapped
Called when player is about to be incapaciated
hook.Add( "PlayerBlockIncapaciation", "identifier", function( ply, att, dmg, inf )
end )

--[[ Hook "PlayerBleed"
	arguments: (Player) ply - player that is incapaciated and bleeding out
	return values: (number) blood - amount of damage player takes while incapaciated per, second
Called every second for each incapped player to determine how much damage is done to them as "bloodloss"
hook.Add( "PlayerBleed", "identifier", function( ply ) -- Speed of bleeding out
end )

--[[ Hook "PlayerRescueRequiredTime"
	arguments: (Player) rescuant - player who is being rescued; (Player) rescuer - player who is about to initiate a rescue; (bool) isreset - if hook is called because of rescue timer reset due to rescuant being damaged
	return values: (number) time - time in seconds it should take for player to rescue another player
Called when player is starting rescue of another player and when rescue timer is reset due to rescuant being damaged
hook.Add( "PlayerRescueRequiredTime", "identifier", function( rescuant, rescuer, isreset ) -- Tells how many seconds it takes to rescue a player
end )

--[[ Hook "ShouldResetRescueOnDamage"
	arguments: (Player) rescuant - player who is being rescued; (Player) rescuer - player who is rescuing; (CTakeDamageInfo) dmginfo - damage that player got
	return values: (bool) reset - if rescue timer should be reset or not
Called when player is taking damage while being rescued. Returning true will reset progress of rescue
hook.Add( "ShouldResetRescueOnDamage", "identifier", function( rescuant, rescuer, dmginfo )
end )

--[[ Hook "GrantPlayerStandUps"
	arguments: (Player) ply - player who died or spawned so their stand ups have to be set
	return values: (number) amount - amount of "Stand-Ups" to grant player by default
Called when player needs to be determined about how many "Stand-Ups" they have per life
hook.Add( "GrantPlayerStandUps", "identifier", function( ply ) 
end )

--[[ Hook "PlayerHealthRestoreOnUnincap"
	arguments: (Player) ply - player who was un-incapaciated; (Player) rescuer - player who rescued this player, not always valud
	return values: (number) health - amount of health that player gets when he is unincapaciated
Called every time player un-incapaciates. This includes death, where return value isn't relevant
hook.Add( "PlayerHealthRestoreOnUnincap", "identifier", function( ply, rescuer )
end )

--[[ Hook "OnPlayerIncapaciated"
	arguments: (Player) ply - player that has been incapaciated
	return values: none
Called every time player is incapaciated
hook.Add( "OnPlayerIncapaciated", "identifier", function( ply )
end )

--[[ Hook "OnPlayerRescued"
	arguments: (Player) rescuant - player that has been rescued; (Player) rescuer - player that has rescued this player
	return values: none
Called every time player is rescued
hook.Add( "OnPlayerRescued", "identifier", function( rescuant, rescuer )
end ) --]]

include( "modifications-example/moreexplosivesdamage.lua" ) -- Look into this file for info