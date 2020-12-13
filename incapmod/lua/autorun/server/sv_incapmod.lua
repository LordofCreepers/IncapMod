-- Released under GNU General Public License 3.0, 2 June 2007, Copyright (C) 2007 Free Software Foundation
-- Last changed: 13 December 2020

----[[ Code ----]]
-- Library initialization
do
	-- Reads all types of debug messages from SettingsEnum table and figures out maximum amount of them
	local settings_enum = settings_enum or IncapMod.SettingsEnum
	local settings_max = settings_max
	if not settings_max then
		local curnum = 0
		for setting, num in pairs( settings_enum ) do
			curnum = curnum + num
		end
		settings_max = curnum
	end
	-- Forms one string from descriptions of debug messages
	local settings_enum_desc = settings_enum_desc or IncapMod.SettingsDescriptions
	local settings_desc = settings_desc
	if not settings_desc then -- Only called if file is not refreshed
		settings_desc = "" -- Sets value to empty string
		for setting, desc in pairs( settings_enum_desc ) do -- Loops through every debug message and it's description
			settings_desc = settings_desc .. "	" .. settings_enum[ setting ] .. " (" .. setting .. ") - " .. desc .. "\n" -- Forms full string formatted in way "Number_of_enumerator (CODE_NAME_OF_ENUMERATOR): Description of enumerator"
		end
	end
	-- "CSL_PRINTBLEEDING" is called rapidly, so I disable it by default
	local settings_default = settings_default or settings_max - settings_enum[ "CSL_PRINTBLEEDING" ]
	if SERVER then
		IncapMod.Cvars.ConsoleSettings = IncapMod.Cvars.ConsoleSettings or CreateConVar( "incapmod_consolemessagesettings", settings_default, FCVAR_ARCHIVE, "Combination of bit settings which are applied to console prints of Incap mod. Possible values:\n" .. settings_desc, 0, settings_max )
	end
	-- Forms an updater for list of teams that is set by "incapmod_teamsindexeslist" ConVar
	IncapMod.TeamsList = IncapMod.TeamsList or {} -- Initializes table
	local function UpdateTeamsIndexesList( cvarname, oldVal, newVal )
		table.Empty( IncapMod.TeamsList ) -- As far as we have new value, we refresh this every time cvar is updated, so this throws away all indexes that was there to add new
		if newVal == "" then return end -- Discards if nothing was entered
		if not newVal:find( " ", 1, false ) then -- If new string contains no spaces, code assumes it has only one team and operates as that
			if not tonumber( newVal ) then return end -- Discards if entered value is not number
			if not team.Valid( idx ) then -- If team is not valid, print to console and halt
				ErrorNoHalt( ( debug.traceback() .. ": failed to find team with index " .. idx .. ", ignoring\n"):gsub( "stack traceback:\n	", "[IncapMod] " ) )
				return
			end
			IncapMod.TeamsList[ tonumber( newVal ) ] = true -- Inserts team into table which servers as a shortcut to code to not parse string every time
			return
		end
		for _, idx in ipairs( newVal:Split( " " ) ) do -- Seperates string into table divided by spaces assuming each space seperates new values
			idx = tonumber( idx ) -- Transfers team's index to number
			if not team.Valid( idx ) then -- If cannot find valid team of that index, print to console and keep looping
				ErrorNoHalt( ( debug.traceback() .. ": failed to find team with index " .. idx .. ", ignoring\n"):gsub( "stack traceback:\n	", "[IncapMod] " ) )
				continue
			end
			IncapMod.TeamsList[ idx ] = true
		end
	end
	cvars.AddChangeCallback( IncapMod.Cvars.TeamsListIndexes:GetName(), UpdateTeamsIndexesList ) -- Binds updater function above to every time ConVar is changed
	local function SetCvarFromString( cvar, datastring ) -- Shortcut function for reading value of ConVar from string
		if datastring == "" then return end -- If file is empty, quit function execution
		local _, nameend = datastring:find( cvar:GetName(), 1, true ) -- Tries to find name of cvar in file
		if not nameend then return end -- If not succeded, quit function execution
		local _, closingend = datastring:find( "\n", nameend, true ) -- Tries to find end of value assignment, signified by newline
		if not closingend then return end -- If failed, quit function execution
		-- TODO: it's probably not possible to not find result in this scenario. Perhaps attempts to find newline will always give the result, although it might be buggy
		-- So this function might just do not do anything
		local valuestring = datastring:sub( nameend, closingend ) -- Reads the line of convar and value assigned
   		valuestring = valuestring:match( '%b""' ) -- Find value contained in double quotes
		cvar:SetString( valuestring:gsub( '"', "" ) ) -- Remove quotes and set ConVar value to read value
	end
	local function SaveCvarToFile( cvarname, _, newVal ) -- Shortcut function for dumping changed ConVars to disk
		local filecontent = file.Read( "incapmod_cfg.txt", "DATA" ) -- Reads content of config file
		local namestart = ( filecontent:find( cvarname, 1, true ) ) -- Tries to find already existing entry for this ConVar by name
		if not namestart then -- If fails, adds new entry, saves value to it and halts
			file.Append( "incapmod_cfg.txt", cvarname .. '	"' .. tostring( newVal ) .. '"\n' )
			return
		end
		local _, valueend = filecontent:find( "\n", namestart, true ) -- Tries to find end of current line
		if not valueend then return end -- If fails, stops function execution
		-- TODO: basically, same thing as above
		filecontent = filecontent:Replace( filecontent:sub( namestart, valueend ), cvarname .. '	"' .. tostring( newVal ) .. '"\n' ) -- Replaces old entry with new one, changing the value
		file.Write( "incapmod_cfg.txt", filecontent ) -- Dumps changes to text file
	end
	-- So, for whatever reason FCVAR_ARCHIVE does saves ConVars to .cfg, but just doesn't read it, so values are reset after server restart
	-- Basically, here we're just writing values to our own file so it works. You can find this file in "garrysmod/data/incapmod_cfg.txt"
	hook.Add( "PostGamemodeLoaded", "LoadSavedCvars", function()
		local convarsdatastring = file.Read( "incapmod_cfg.txt", "DATA" ) -- Tries to read content of file
		if not convarsdatastring then -- If file is empty, create a new one and write disclamer to it
			file.Write( "incapmod_cfg.txt", "//Because FCVAR_ARCHIVE doesn't save ConVars for some reasons, code does it manually\n//This is the file where all settings are saved\n\n\n" )
			convarsdatastring = "" -- Set this to empty, so if file was initialy empty, no data is written there and there's no point in looking for values
		end
		for _, cvar in pairs( IncapMod.Cvars ) do -- Loops through all ConVars of this addon
			SetCvarFromString( cvar, convarsdatastring ) -- Calls a shortcut function to read default values from text file
			cvars.AddChangeCallback( cvar:GetName(), SaveCvarToFile ) -- Binds update of each ConVar to shorcut function
		end
		UpdateTeamsIndexesList( IncapMod.Cvars.TeamsListIndexes:GetName(), "", IncapMod.Cvars.TeamsListIndexes:GetString() ) -- Forces refresing of the teams indexes list after it was loaded
	end )
	cvars.AddChangeCallback( IncapMod.Cvars.Enabled:GetName(), function( cvarname, oldVal, newVal ) -- This is called upon changing ConVar "incapmod_enabled" and required to properly disable this mod at runtime
		if tobool( newVal ) then return end -- Only triggers if IncapMod is actually disabled
		local incapped_players = table.Copy( IncapMod.IncappedPlayers ) -- Copies table as long as original table is going to be changed
		for ply, _ in pairs( incapped_players ) do -- Unincapaciates all players
			ply:UnIncap()
		end
	end )
end
do
	local Player = FindMetaTable( "Player" )
	IncapMod.BonesOffset = Vector( 0, 0, -29.5 )
	IncapMod.BonesRotation = Angle( 0, 0, -90 )
	--[[ Function Player:Incap
		arguments: none
		return values: none
	Incapaciates player function is called on --]]
	function Player:Incap()
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if self:IsIncapacitated() then return end
		hook.Run( "OnPlayerIncapacitated", self )
		self.MaxHealth = self:GetMaxHealth()
		self:SetHealth( hook.Run( "PlayerIncappedHealth", self ) or IncapMod.Cvars.IncapHealth:GetFloat() )
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
		self.nextDmg = CurTime() + ( hook.Run( "PlayerBleedingInterval", ply ) or IncapMod.Cvars.BleedingInterval:GetFloat() )
		if IsValid( self:GetActiveWeapon() ) then
			if not IncapMod.AllowedWeapons[ self:GetActiveWeapon():GetClass() ] then
				for wep, _ in pairs( IncapMod.AllowedWeapons ) do
					if self:HasWeapon( wep ) then
						self.NextSelectWeapon = wep
						break
					end
				end
			else
				self.NextSelectWeapon = self:GetActiveWeapon():GetClass()
			end
		end
		if not self.NextSelectWeapon then
			self:SetActiveWeapon( NULL )
			self:RemoveAllGestures()
			self:AddGestureSequence( self:LookupSequence( IncapMod.DeathSeq ), false )
		else
			self:ManipulateBonePosition( 0, IncapMod.BonesOffset )
			self:ManipulateBoneAngles( 0, IncapMod.BonesRotation )
		end
	end
	--[[ Function Player:UnIncap
		arguments: none
		return values: none
	Un-incapaciates player function is called on --]]
	function Player:UnIncap()
		if not self:IsIncapacitated() then return end
		self:SetNWBool( "IsIncapped", false )
		self:ManipulateBonePosition( 0, vector_origin )
		self:ManipulateBoneAngles( 0, angle_zero )
		self:ClearRescue()
		self:SetMaxHealth( self.MaxHealth )
		self:SetHealth( hook.Run( "PlayerHealthRestoreOnUnincap", self, self:GetRescuedBy() ) or self.MaxHealth * IncapMod.Cvars.RestorePortion:GetFloat() )
		self.MaxHealth = nil
		self:SetNWFloat( "MaxIncappedHealth", 0 )
		self:RemoveGesture( self:LookupSequence( IncapMod.DeathSeq ) )
		IncapMod.IncappedPlayers[ self ] = nil
		self:AllowFlashlight( self.FlashlightAllowed )
		self.FlashlightAllowed = nil
		self.nextDmg = nil
		if not IncapMod.Cvars.AccelMemory:GetBool() then
			self.dmgTaken = 0
		end
		self.attacker = nil
	end
	--[[ Function Player:ClearRescue
		arguments: none
		return values: none
	If someone is rescuing this player, rescue will be stopped --]]
	function Player:ClearRescue()
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if not self:IsIncapacitated() then return end
		if IsValid( self:GetRescuedBy() ) then
			self:GetRescuedBy():SetNWEntity( "PlayerRescuing", NULL )
		end
		self:SetRescueTimer( 0, 0 )
		self:SetNWEntity( "RescuingPlayer", NULL )
	end
	--[[ Function Player:SetRescue
		arguments: (Player) player to start rescue by
		return values: none
	Initiate a rescue of this player by pointed player --]]
	function Player:SetRescue( ply )
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if not self:IsIncapacitated() then return end
		if hook.Run( "PlayerBlockRescue", ply, self ) then return end
		self:SetNWEntity( "RescuingPlayer", ply )
		self:StartRescueTimer( 0, hook.Run( "PlayerRescueRequiredTime", self, ply, false ) or IncapMod.Cvars.PlayerRescueDefaultTime:GetFloat() )
		ply:SetNWEntity( "PlayerRescuing", self )
	end
	--[[ Function Player:SetRescueTimer
	arguments: (number) starttime - start time relative to CurTime; (number) endtime - end time relative to CurTime
	return values: none
	Sets rescue timer directly --]]
	function Player:SetRescueTimer( starttime, endtime )
		if not self:IsIncapacitated() then return end
		self:SetNWFloat( "RescueStartTime", starttime )
		self:SetNWFloat( "RescueEndTime", endtime )
	end
	--[[ Function Player:AdvanceRescueTimer
	arguments: (number) starttime - timer start adjustment; (number) endtime - timer end adjustment
	return values: none
	"Offsets" rescue timer --]]
	function Player:AdvanceRescueTimer( starttime, endtime )
		if not self:IsIncapacitated() then return end
		self:SetNWFloat( "RescueStartTime", self:GetNWFloat( "RescueStartTime", 0 ) + starttime )
		self:SetNWFloat( "RescueEndTime", self:GetNWFloat( "RescueEndTime", 0 ) + endttime )
	end
	--[[ Function Player:StartRescueTimer
	arguments: (number) startoffset - timer start offset; (number) duration - timer duration
	return values: none
	Sets player's rescue timer, where start is CurTime() + startoffset and end is CurTime() + duration --]]
	function Player:StartRescueTimer( startoffset, duration )
		self:SetNWFloat( "RescueStartTime", CurTime() + startoffset )
		self:SetNWFloat( "RescueEndTime", CurTime() + duration )
	end
	--[[ Function Player:GiveStandUps
	arguments: (number) amount - amount of "Stand-Ups" to increase by
	return values: none
	Increases player's "Stand-Ups" --]]
	function Player:GiveStandUps( amount )
		self:SetNWInt( "StandUpsLeft", self:GetNWInt( "StandUpsLeft", 0 ) + math.Round( amount ) )
	end
	--[[ Function Player:SetStandUps
	arguments: (number) amount - amount of "Stand-Ups" to set to
	return values: none
	Sets player's "Stand-Ups" --]]
	function Player:SetStandUps( amount )
		self:SetNWInt( "StandUpsLeft", math.Round( amount ) )
	end
	--[[ Function Player:SetTimesCanBeIncapacitated
	arguments: (number) amount - new value of how many times player can be incapacitated
	return values: none
	Sets amount of times player can be incapacitated by damage before they die. Set to negative value to disable this feature --]]
	function Player:SetTimesCanBeIncapacitated( num )
		self:SetNWInt( "TimesCanBeIncapped", math.Round( num ) )
	end
	--[[ Function Player:AddTimesCanBeIncapacitated
	arguments: (number) offset - by what value times player can be incapacitated should be increased
	return values: none
	Adjusts amount of times player can be incapacitated by pointed number --]]
	function Player:AddTimesCanBeIncapacitated( num )
		self:SetNWInt( "TimesCanBeIncapped", self:TimesCanBeIncapacitated() + math.Round( num ) )
	end
end

-- Hook run every time something takes damage
hook.Add( "EntityTakeDamage", "ModifyIncapDamage", function( target, dmginfo )
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	if not target:IsPlayer() then return end -- Discards execution of the code below if target is not player
	if not target:IsIncapacitated() then -- Checks if not incapped
		if target:Health() - dmginfo:GetDamage() > 0 then return end -- Discards if player isn't going to be dead after damage
		if target:TimesCanBeIncapacitated() <= 0 and target:TimesCanBeIncapacitated() > -1 then return end
		if ( IncapMod.Cvars.TeamsSubList:GetBool() and IncapMod.TeamsList[ target:Team() ] ) or ( not IncapMod.Cvars.TeamsSubList:GetBool() and not IncapMod.TeamsList[ target:Team() ] ) then return end
		if hook.Run( "PlayerBlockIncapacitation", target, dmginfo:GetAttacker(), dmginfo:GetDamage(), dmginfo:GetInflictor() ) then return end -- Player will die if "PlayerBlockIncapacitation" returns true
		if target:TimesCanBeIncapacitated() > 0 then -- If times player can be incapacitated is currently limited, decreases it by one
			target:AddTimesCanBeIncapacitated( -1 )
		end
		target:Incap() -- Incaps player
		target.attacker = dmginfo:GetAttacker() -- Sets the incapaciator. Optional
		if bit.band( IncapMod.Cvars.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTINCAP" ] ) <= 0 then return true end
		print( "Player " .. target:Nick() .. " has been incapacitated" ) -- Prints into console
		return true -- Blocks fatal damage
	else
		target.dmgTaken = target.dmgTaken + dmginfo:GetDamage()
	end
end )

hook.Add( "PostEntityTakeDamage", "ResetRescueTimer", function( ent, dmginfo, took )
	if not IncapMod.Cvars.Enabled:GetBool() then return end -- Discards if IncapMod is disabled
	if not ent:IsPlayer() then return end -- Discards if entity that took damage is not player
	if not ent:IsIncapacitated() then return end -- Discards if player is not incapacitated
	if not IsValid( ent:GetRescuedBy() ) then return end -- Discards if player is not rescued
	if not hook.Run( "ShouldResetRescueOnDamage", ent, ent:GetRescuedBy(), dmginfo, took ) and dmginfo:GetDamage() < IncapMod.Cvars.RescueDamageResetThreshold:GetFloat() then return end -- Discards if player took less damage than he should
	ent:StartRescueTimer( 0, ( hook.Run( "PlayerRescueRequiredTime", ent, ent:GetRescuedBy(), true ) or IncapMod.Cvars.PlayerRescueDefaultTime:GetFloat() ) ) -- Resets (restarts) the rescue timer
end )

-- Hook that runs every time player is dead
hook.Add( "PlayerDeath", "RestoreIncap", function( ply, inf, att )
	-- Unincappes players on their death so effect won't stay after
	timer.Simple( 0, function()
		ply:UnIncap()
	end )
end )

-- Same as above, but when player is killed silently
hook.Add( "PlayerDeathSilent", "RestoreIncap", function( ply )
	-- Same, but for silent death
	ply:UnIncap()
end )

-- Runs every time player is respawned
hook.Add( "PlayerSpawn", "ResetBleedingAcceleration", function( ply )
	ply.dmgTaken = 0
end )

-- Runs every tick
hook.Add( "Think", "DamageIncappedOnes", function()
	if not IncapMod.Cvars.Enabled:GetBool() then return end -- Discards if IncapMod is disabled
	for ply, _ in pairs( IncapMod.IncappedPlayers ) do
		if not ( CurTime() >= ply:GetNWFloat( "RescueEndTime", 0 ) and ply:GetNWFloat( "RescueStartTime", 0 ) ~= 0 and IsValid( ply:GetNWEntity( "RescuingPlayer", nil ) ) ) then
			if not ply:IsIncapacitated() then continue end -- Discards if player is not incapacitated
			if CurTime() < ply.nextDmg or IsValid( ply:GetRescuedBy() ) then continue end -- Discards if cooldown on damage hasn't pass or player has a rescuer
			ply.nextDmg = CurTime() + ( hook.Run( "PlayerBleedingInterval", ply ) or IncapMod.Cvars.BleedingInterval:GetFloat() ) -- Sets cooldown
			local damage = hook.Run( "PlayerBleed", ply, ply.dmgTaken ) or ( IncapMod.Cvars.Bleedout:GetFloat() + ( ( IncapMod.Cvars.BleedingAcceleration:GetFloat() > 0 and ply.dmgTaken / IncapMod.Cvars.BleedingAcceleration:GetFloat() ) or 0 ) )
			if ply:Health() <= damage then
				-- "Kills" player if he's out of health
				local dmgInfo = DamageInfo()
				dmgInfo:SetAttacker( ply.attacker or game.GetWorld() )
				dmgInfo:SetDamage( ply:Health() ) -- Builds "Damage data"
				ply:SetArmor( 0 ) -- Sets armor to 0 so it doesn't consume damage
				ply:TakeDamageInfo( dmgInfo ) -- Damages player so it kills them
				if bit.band( IncapMod.Cvars.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTBLEEDOUT" ] ) <= 0 then return end -- Don't run if printing of bleeding out is disabled
				print( "Player " .. ply:Nick() .. " lost " .. tostring( math.abs( dmgInfo:GetDamage() ) ) .. " liters of blood and died due to bloodloss " ) -- Prints to console when player died due to bloodloss
			else
				ply:SetHealth( ply:Health() - damage ) -- Decreases player's health
				if bit.band( IncapMod.Cvars.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTBLEEDING" ] ) <= 0 then return end -- Checks if printing of bleeding is disabled
				print( "Player " .. ply:Nick() .. " lost " .. damage .. " liters of blood" ) -- Prints to console when player is bleeding
			end
		else
			if bit.band( IncapMod.Cvars.ConsoleSettings:GetInt(), IncapMod.SettingsEnum[ "CSL_PRINTRESCUE" ] ) > 0 then -- Checks if printing of rescuing is disabled
				print( "Player " .. ply:Nick() .. " has been rescued by " .. ply:GetRescuedBy():Nick() ) -- Prints to console when player is rescued
			end
			hook.Run( "OnPlayerRescued", ply, ply:GetRescuedBy() )
			ply:UnIncap() -- Un-incapaciates player
		end
	end
end )

-- Hook that affects player's inputs
hook.Add( "StartCommand", "RestrictPlayerMovementWhileIncapacitatedAndRescuing", function( ply, cmd )
	if not IncapMod.Cvars.Enabled:GetBool() then return end -- Doesn't run if IncapMod is disabled
	ply.result_speed = hook.Run( "PlayerIncappedSpeed", ply ) or IncapMod.Cvars.MoveSpeed:GetFloat() -- Caches max speed to not call hook twice
	if ply:IsIncapacitated() then
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
		if ply.result_speed <= 0 or ( not IncapMod.Cvars.MoveWhenRescued:GetBool() and IsValid( ply:GetRescuedBy() ) ) then
			cmd:ClearMovement() -- Blocks movement when max incapped speed is 0 or below or player is being rescued
		end
	-- Rescue stuff
	elseif cmd:KeyDown( IN_USE ) and IsValid( ply:GetCurrentlyRescuedPlayer() ) and ply:GetCurrentlyRescuedPlayer() ~= ply then -- Checks if player is holding use key and is rescuing someone
		if ply:GetEyeTraceNoCursor().Entity ~= ply:GetCurrentlyRescuedPlayer() or ply:GetEyeTraceNoCursor().Entity:GetPos():DistToSqr( ply:GetPos() ) > IncapMod.Cvars.MaxRescueDist:GetInt() ^ 2 or not ply:GetCurrentlyRescuedPlayer():IsIncapacitated() or ply:IsIncapacitated() then -- Interrupts rescue if rescuer is not looking at rescuant anymore, too far, rescuant became non-incapacitated or rescuer was incapacitated
			ply:GetCurrentlyRescuedPlayer():ClearRescue()
			return
		else
			cmd:SetButtons( IN_USE )
			cmd:ClearMovement() -- Blocks rescuer from moving while rescuing
		end
	elseif IsValid( ply:GetCurrentlyRescuedPlayer() ) and not cmd:KeyDown( IN_USE ) then -- Interrupts rescue if rescuer doesn't hold use key anymore
		ply:GetCurrentlyRescuedPlayer():ClearRescue()
	elseif not IsValid( ply:GetCurrentlyRescuedPlayer() ) and cmd:KeyDown( IN_USE ) then -- Looks if currently isn't rescuing anyone and is holding a use key
		if ply:IsIncapacitated() then return end -- Blocks incapacitated players from rescuing other players
		if not ply:GetEyeTraceNoCursor().Entity:IsPlayer() then return end -- Blocks from rescuing anything else other than player
		if not ply:GetEyeTraceNoCursor().Entity:IsIncapacitated() then return end -- Blocks from rescuing non-incapacitated players
		if ply:GetEyeTraceNoCursor().Entity:GetPos():DistToSqr( ply:GetPos() ) > IncapMod.Cvars.MaxRescueDist:GetInt() ^ 2 then return end
		if hook.Run( "PlayerBlockRescue", ply, ply:GetEyeTraceNoCursor().Entity ) then return end -- Blocks resue if "PlayerBlockRescue" return true
		if ply:Team() ~= ply:GetEyeTraceNoCursor().Entity:Team() and IncapMod.Cvars.OnlyTeammates:GetBool() then return end -- If "incapmod_rescueteammatesonly" is set to 1, blocks rescue if players are from different teams
		ply:GetEyeTraceNoCursor().Entity:SetRescue( ply ) -- Starts rescue
	end
end )

hook.Add( "SetupMove", "RestrictPlayerMove", function( ply, mv, cmd ) -- Also restricts movement. Required in case if player can move while incapped
	if not IncapMod.Cvars.Enabled:GetBool() then return end -- Doesn't run if IncapMod is disabled
	if not ply:IsIncapacitated() then return end -- Doesn't run if player is not incapacitated
	if ply.result_speed <= 0 then return end -- Doesn't run if max player speed while incapped is 0 or below
	mv:SetMaxClientSpeed( ply.result_speed ) -- Restricts speed to max speed
end )



----[[ Interfaces ----]]
-- These are gradients that are shown on player's screen when he is incapacitated
-- If you have overriden "DrawPlayerOnIncap" hook, and it doesn't include these, you can delete it
resource.AddFile( "materials/sprites/grad-incap.png" )
resource.AddFile( "materials/sprites/grad-incap-pain.png" )
resource.AddFile( "materials/sprites/death-skull.png" )
resource.AddFile( "materials/sprites/plain-arrow.png" )

-- These hooks are for customization purposes. You can override them and even delete them (in which case value is reset to default one)

--[[ Hook "PlayerBlockIncapacitation"
	arguments: (Player) ply - player that is about to be incapacitated; (Entity) att - entity that incapacitated player; (CTakeDamageInfo) dmg - damage info of the final blow; (Entity) inf - inflictor of the damage
	return values: (bool) allow - determines if player should be incapacitated. If not returned "false" or "nil", player will die instead of being incapped
Called when player is about to be incapacitated
hook.Add( "PlayerBlockIncapacitation", "identifier", function( ply, att, dmg, inf )
	return
end )

--[[ Hook "PlayerBleed"
	arguments: (Player) ply - player that is incapacitated and bleeding out; (number) dmg - damage that was taken by this player during Incapacitation
	return values: (number) blood - amount of damage player takes while incapacitated, per second
Called every second for each incapped player to determine how much damage is done to them as "bloodloss"
hook.Add( "PlayerBleed", "identifier", function( ply, dmg ) -- Speed of bleeding out
	return 5
end )

--[[ Hook "PlayerBleedingInterval"
	arguments: (Player) ply - player that is incapacitated and bleeding out; (number) dmg - damage that was taken by this player during Incapacitation
	return values: (number) interval - total time, in seconds, that should pass before player will take another portion of damage by Incapacitation
Called before player takes damage in order to determine when player should take this damage next
hook.Add( "PlayerBleedingInterval", "identifier", function( ply, dmg ) 
	return 1
end )

--[[ Hook "PlayerRescueRequiredTime"
	arguments: (Player) rescuant - player who is being rescued; (Player) rescuer - player who is about to initiate a rescue; (bool) isreset - if hook is called because of rescue timer reset due to rescuant being damaged
	return values: (number) time - time in seconds it should take for player to rescue another player
Called when player is starting rescue of another player and when rescue timer is reset due to rescuant being damaged
hook.Add( "PlayerRescueRequiredTime", "identifier", function( rescuant, rescuer, isreset ) -- Tells how many seconds it takes to rescue a player
	return 5
end )

--[[ Hook "ShouldResetRescueOnDamage"
	arguments: (Player) rescuant - player who is being rescued; (Player) rescuer - player who is rescuing; (CTakeDamageInfo) dmginfo - damage that player got
	return values: (bool) reset - if rescue timer should be reset or not
Called when player is taking damage while being rescued. Returning true will reset progress of rescue
hook.Add( "ShouldResetRescueOnDamage", "identifier", function( rescuant, rescuer, dmginfo )
	return true
end )

--[[ Hook "PlayerHealthRestoreOnUnincap"
	arguments: (Player) ply - player who was un-incapacitated; (Player) rescuer - player who rescued this player, not always valud
	return values: (number) health - amount of health that player gets when he is unincapacitated
Called every time player un-incapaciates. This includes death, where return value isn't relevant
hook.Add( "PlayerHealthRestoreOnUnincap", "identifier", function( ply, rescuer )
	return ply:GetMaxHealth() * 0.3
end )

--[[ Hook "OnPlayerIncapacitated"
	arguments: (Player) ply - player that has been incapacitated
	return values: none
Called every time player is incapacitated
hook.Add( "OnPlayerIncapacitated", "identifier", function( ply )
end )

--[[ Hook "OnPlayerRescued"
	arguments: (Player) rescuant - player that has been rescued; (Player) rescuer - player that has rescued this player
	return values: none
Called every time player is rescued
hook.Add( "OnPlayerRescued", "identifier", function( rescuant, rescuer )
end ) --]]

include( "modifications-example/moreexplosivesdamage.lua" ) -- Look into this file for info

-- Called every time player spawns
hook.Add( "PlayerSpawn", "SetVariablesOnSpawn", function( ply ) -- This is here so you can override amount of times players can rescue themselves and times they can be Incapacitated
	ply:SetStandUps( IncapMod.Cvars.StartingStandUps:GetInt() ) -- Resets amount of "Stand-Ups" player have
	ply:SetTimesCanBeIncapacitated( IncapMod.Cvars.DefaultIncapTimes:GetInt() ) -- Resets amount of "Incap times" player have
end )