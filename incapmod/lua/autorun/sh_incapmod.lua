-- Released under GNU General Public License 3.0, 2 June 2007, Copyright (C) 2007 Free Software Foundation
-- Last changed: 13 December 2020

----[[ Code ----]]
-- Library initialization
IncapMod = IncapMod or {} -- Main table initialization
IncapMod.IncappedPlayers = IncapMod.IncappedPlayers or {} -- List of incapacitated players. Changed at runtime
IncapMod.SettingsEnum = IncapMod.SettingsEnum or { CSL_PRINTINCAP = 1, CSL_PRINTBLEEDING = 2, CSL_PRINTBLEEDOUT = 4, CSL_PRINTRESCUE = 8 } -- Enums of debug messages
IncapMod.SettingsDescriptions = IncapMod.SettingsDescriptions or { -- Descriptions of debug messages
	CSL_PRINTINCAP = "Print in console when player is incapacitated",
	CSL_PRINTBLEEDING = "Print in console every time player takes damage due to bleedout",
	CSL_PRINTBLEEDOUT = "Print in console when player died due to bleedout",
	CSL_PRINTRESCUE = "Print in console when player is rescued"
}
IncapMod.DeathSeq = "death_03"
do
	-- Initialization of all ConVars
	IncapMod.Cvars = IncapMod.Cvars or {}
	IncapMod.Cvars.Enabled = IncapMod.Cvars.Enabled or CreateConVar( "incapmod_enabled", 1, FCVAR_REPLICATED, "Whether IncapMod is enabled or not", 0, 1 )
	IncapMod.Cvars.IncapHealth = IncapMod.Cvars.IncapHealth or CreateConVar( "incapmod_healthonincap", 500, FCVAR_REPLICATED, "Amount of health given to incapacitated players", 1 )
	IncapMod.Cvars.MaxRescueDist = IncapMod.Cvars.MaxRescueDist or CreateConVar( "incapmod_defaultmaxrescuedist", 100, FCVAR_REPLICATED, "Default maximum distance at which player can be rescued", 1 )
	IncapMod.Cvars.RescueDamageResetThreshold = IncapMod.Cvars.RescueDamageResetThreshold or CreateConVar( "incapmod_rescuedmgresetthreshold", 0, FCVAR_REPLICATED, "Maximum amount of damage that cannot affect rescue timer. If damage is above or equal to this value and player is rescued, rescue timer will be reset" )
	IncapMod.Cvars.Bleedout = IncapMod.Cvars.Bleedout or CreateConVar( "incapmod_basebleedoutspeed", 5, FCVAR_REPLICATED, 'Amount of health drained per second while incapacitated. Will take no effect if "PlayerBleed" hook return any value', 0 )
	IncapMod.Cvars.BleedingInterval = IncapMod.Cvars.BleedingInterval or CreateConVar( "incapmod_bleedinginterval", 1, FCVAR_REPLICATED, "Time, in seconds, in which player is going to bleed. Will take no effect if overriden by code", 0 )
	IncapMod.Cvars.BleedingAcceleration = IncapMod.Cvars.BleedingAcceleration or CreateConVar( "incapmod_bleedingaccel", 25, FCVAR_REPLICATED, 'Amount of damage it takes to increase bleeding speed by 1. Acceleration is only influenced by external damage, not incapacity damage itself. Set to zero or below to disable. Will take no effect if "PlayerBleed" hook return any value' )
	IncapMod.Cvars.PlayerRescueDefaultTime = IncapMod.Cvars.PlayerRescueDefaultTime or CreateConVar( "incapmod_rescuetime", 5, FCVAR_REPLICATED, 'Amount of time it takes to rescue player, in seconds. Will take no effect if "PlayerRescueRequiredTime" hook return any value' )
	IncapMod.Cvars.OnlyTeammates = IncapMod.Cvars.OnlyTeammates or CreateConVar( "incapmod_rescueteammatesonly", 1, FCVAR_REPLICATED, 'When set to 1, players can only be rescued by their teammates', 0, 1 )
	IncapMod.Cvars.StartingStandUps = IncapMod.Cvars.StartingStandUps or CreateConVar( "incapmod_playerstandupsonspawn", 0, FCVAR_REPLICATED, 'How many "Stand-Ups" player has on respawn by default. Will take no effect if "GrantPlayerStandUps" hook return any value', 0 )
	IncapMod.Cvars.MoveSpeed = IncapMod.Cvars.MoveSpeed or CreateConVar( "incapmod_maxspeedwhileincapped", 0, FCVAR_REPLICATED, 'What speed incapped players have. Will take no effect if "PlayerIncappedSpeed" hook return any value', 0 )
	IncapMod.Cvars.MoveWhenRescued = IncapMod.Cvars.MoveWhenRescued or CreateConVar( "incapmod_canmovewhilerescued", 0, FCVAR_REPLICATED, "When set to 1, player can move while being rescued", 0, 1 )
	IncapMod.Cvars.RestorePortion = IncapMod.Cvars.RestorePortion or CreateConVar( "incapmod_healthportiontorestore", 0.3, FCVAR_REPLICATED, 'Portion of health to restore when rescued. Will take no effect if "PlayerHealthRestoreOnUnincap" hook return any value', 0.05 )
	IncapMod.Cvars.ShowDefaultHUD = IncapMod.Cvars.ShowDefaultHUD or CreateConVar( "incapmod_showdefaulthud", 1, FCVAR_REPLICATED, "When set to 1, shows default HUD of IncapMod", 0, 1 )
	IncapMod.Cvars.XrayDeathMarks = IncapMod.Cvars.XrayDeathMarks or CreateConVar( "incapmod_showdeathmarksthroughwalls", 0, FCVAR_REPLICATED, 'When set to 1, shows death marks above incapacitated players heads through walls. If "incapmod_rescueteammatesonly" is set to 1, this feature will only work for teammates', 0, 1 )
	IncapMod.Cvars.TeamsSubList = IncapMod.Cvars.TeamsSubList or CreateConVar( "incapmod_teamssubtractivelist", 1, FCVAR_REPLICATED, "If set to 0, players can only be incapacitated if they're members of team that is in the list. If set to 1, players can only be incapacitated if they're NOT members of team that is in the list", 0, 1 )
	IncapMod.Cvars.TeamsListIndexes = IncapMod.Cvars.TeamsListIndexes or CreateConVar( "incapmod_teamsindexeslist", "", FCVAR_REPLICATED, 'List of teams indexes, separated by spaces, which are granted or revoked their ability to be incapacitated, determined by "' .. IncapMod.Cvars.TeamsSubList:GetName() .. '"' )
	IncapMod.Cvars.WeaponsSubList = IncapMod.Cvars.WeaponsSubList or CreateConVar( "incapmod_weaponssubtractivelist", 0, FCVAR_REPLICATED, "If set to 0, incapacitated players can only use weapons from this list. If set to 1, incapacitated players can only use weapons that are NOT listed in this list", 0, 1 )
	IncapMod.Cvars.WeaponsListNames = IncapMod.Cvars.WeaponsListNames or CreateConVar( "incapmod_weaponsnameslist", "weapon_pistol weapon_357", FCVAR_REPLICATED, 'List of names of weapons separated by spaces that are allowed or disallowed to be used by incapacitated players, determined by "' .. IncapMod.Cvars.WeaponsSubList:GetName() .. '"' )
	IncapMod.Cvars.DefaultIncapTimes = IncapMod.Cvars.DefaultIncapTimes or CreateConVar( "incapmod_defaulttimescanbeincapacitated", -1, FCVAR_REPLICATED, "Amount of times player can be incapacitated by damage before dying. Set to negative value to make this infinite" )
	IncapMod.Cvars.AccelMemory = IncapMod.Cvars.AccelMemory or CreateConVar( "incapmod_bleedingaccelerationmemory", 1, FCVAR_REPLICATED, "If set to 1, bleeding acceleration is not reset after successful rescue", 0, 1 )
	concommand.Add( "incapmod_getteamindex", function( ply, cmd, args, argStr )
		-- Function for getting indexes of a team by name
		for idx, team in ipairs( team.GetAllTeams() ) do
			if team.Name ~= args[ 1 ]:gsub( '"', "" ) then continue end
			print( team.Name .. "'s index: " .. idx )
			break
		end
	end, function( cmd, stringargs )
		local autocompletemessages = {}
		stringargs = stringargs:Trim()
		stringargs = stringargs:lower()
		for _, team in ipairs( team.GetAllTeams() ) do
			if not team.Name:find( stringargs ) then continue end
			autocompletemessages[ #autocompletemessages + 1 ] = cmd .. ' "' .. team.Name .. '"'
		end
		return autocompletemessages
	end, "Gets index of entered team" )
	IncapMod.AllowedWeapons = IncapMod.AllowedWeapons or {} -- Shortcut table for weapon names
	local function UpdateWeaponsNamesList( cvarname, oldVal, newVal ) -- Function for refreshing things
		table.Empty( IncapMod.AllowedWeapons ) -- Throws out everything from table since we're overwriting anyway
		if newVal == "" then return end -- If nothing was entered, discard
		if not newVal:find( " ", 1, false ) then -- If value has no spaces, assuming cvar is set to only one weapon name
			IncapMod.AllowedWeapons[ newVal ] = true
			return
		end
		for _, name in ipairs( newVal:Split( " " ) ) do -- Seperates string of ConVar by spaces, assuming each space seperates weapon name
			IncapMod.AllowedWeapons[ name ] = true
		end
	end
	-- Refreshes list at the bootup of server
	hook.Add( "PostGamemodeLoaded", "FillInListsOnStartup", function()
		timer.Simple( 0, function() -- Skips one frame in order to make sure that ConVar was loaded from file
			UpdateWeaponsNamesList( IncapMod.Cvars.WeaponsListNames:GetName(), "", IncapMod.Cvars.WeaponsListNames:GetString() ) -- Forces refreshing
		end )
	end )
	cvars.AddChangeCallback( "incapmod_weaponsnameslist", UpdateWeaponsNamesList ) -- Binds update of this cvar to refresher function
end
do
	local Player = FindMetaTable( "Player" )
	--[[ Function Player:IsIncapacitated
		arguments: none
		return values: (bool) incapped - if player function is called on is incapacitated
	Checks if player is Incapacitated --]]
	function Player:IsIncapacitated()
		return self:GetNWBool( "IsIncapped", false ) or tobool( IncapMod.IncappedPlayers[ self ] )
	end
	--[[ Function Player:GetCurrentlyRescuedPlayer
		arguments: none
		return values: (Player) rescuant - player that is being rescued by the player function is called on
	Retrieves who is currently rescued by this player. Will be NULL Entity if player doesn't rescue anyone --]]
	function Player:GetCurrentlyRescuedPlayer()
		return self:GetNWEntity( "PlayerRescuing", NULL )
	end
	--[[ Function Player:GetRescuedBy
		arguments: none
		return values: (Player) rescuer - player that is rescuing the player function is called on 
	Retrieves who is currently rescuing this player. Will be NULL Entity if no one rescues this player --]]
	function Player:GetRescuedBy()
		return self:GetNWEntity( "RescuingPlayer", NULL )
	end
	--[[ Function Player:RescueTimeLeft
		arguments: none
		return values: (number) time - amount of time before the player will be rescued. This will be -1 if player is not being rescued
	Returns time left, in seconds, until rescue should be completed --]]
	function Player:RescueTimeLeft()
		return ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueEndTime", 0 ) - CurTime() ) or -1
	end
	--[[ Function Player:StandUpsLeft
		arguments: none
		return values: (number) amount of times player can stand up by himself before they will need to be rescued
	Gets amount of "Stand-Ups" --]]
	function Player:StandUpsLeft()
		return self:GetNWInt( "StandUpsLeft", 0 )
	end
	--[[ Function Player:GetMaxIncappedHealth
		arguments: none
		return values: (number) health - amount of health that player got once was incapacitated
	If player is incapacitated, returns max health that player got when was incapacitated. Returns 0 if player is not incapacitated --]]
	function Player:GetMaxIncappedHealth()
		return self:GetNWFloat( "MaxIncappedHealth", 0 )
	end
	--[[ Function Player:GetRescueTimer
	arguments: none
	return values: (number) start - start of rescue timer; (number) end - end of rescue timer
	Returns start and end of rescue timer relative to the CurTime, or 0, 0 if player is not rescued --]]
	function Player:GetRescueTimer()
		return ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueStartTime", 0 ) ) or 0, ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueEndTime", 0 ) ) or 0
	end
	--[[ Function Player:GetRescueTimeRatio
	arguments: none
	return values: (number) ratio - gets ratio of start time and end time of rescue timer
	Returs ratio of start time and end time of rescue timer, from 0 (at start) to 1 (at end) --]]
	function Player:GetRescueTimeRatio()
		return ( CurTime() - self:GetNWInt( "RescueStartTime", 0 ) ) / ( self:GetNWInt( "RescueEndTime", 0 ) - self:GetNWInt( "RescueStartTime", 0 ) )
	end
	--[[ Function Player:TimesCanBeIncapacitated
	arguments: none
	return values: (number) times - times player can be incapacitated by damage before they die
	Return amount of time player can be incapacitated before they stop. This only is influenced by incaps on damage. Does not affect calling Player:Incap() directly --]]
	function Player:TimesCanBeIncapacitated()
		return self:GetNWInt( "TimesCanBeIncapped", -1 )
	end
end

-- Hook that runs every time player tries to change their weapons
hook.Add( "PlayerSwitchWeapon", "RestrictSwitchWeapons", function( ply, oldWep, newWep )
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	if ply:IsIncapacitated() and ( ( IncapMod.Cvars.WeaponsSubList:GetBool() and tobool( IncapMod.AllowedWeapons[ newWep:GetClass() ] ) ) or ( not IncapMod.Cvars.WeaponsSubList:GetBool() and not tobool( IncapMod.AllowedWeapons[ newWep:GetClass() ] ) ) ) then return true end -- If player is Incapacitated and wants to change weapons, reads from config and decides if player is actually allowed to change to this weapon
end )

-- Hook that runs when player disconnects
hook.Add( "PlayerDisconnect", "CleanUpIncappedTable", function()
	-- Removes NULL entries from table when player disconnects
	-- Because this hook not always returns valid player, it will clean-up table some time after player disconnected
	timer.Simple( 0.16, function() -- Wait for a while to make sure player has become NULL Entity
		IncapMod.IncappedPlayers[ NULL ] = nil
	end )
end )

-- Hook that runs every time game needs to determine what animation should player play
hook.Add( "CalcMainActivity", "PlayDeathAnimationIfHasNoWeapon", function( ply, spd )
	-- If player has no weapons that are allowed, player plays sequence
	if ply:IsIncapacitated() then -- Code below only executes if player is incapacitated
		if IsValid( ply:GetActiveWeapon() ) then -- If player somehow got weapon that is allowed, stop playing sequence
			if not SERVER then return end -- Only on server
			ply:RemoveGesture( ply:GetSequenceActivity( ply:LookupSequence( IncapMod.DeathSeq ) ) ) -- Removes gesture of playing sequence
			-- Make player lay on ground if he's not
			if ply:GetManipulateBonePosition( 0 ) ~= IncapMod.BonesOffset then
				ply:ManipulateBonePosition( 0, IncapMod.BonesOffset )
			end
			if ply:GetManipulateBoneAngles( 0 ) ~= IncapMod.BonesRotation then
				ply:ManipulateBoneAngles( 0, IncapMod.BonesRotation )
			end
		else
			local seq = ply:LookupSequence( IncapMod.DeathSeq ) -- Finds sequence
			if seq < 0 then return end -- If sequence is not found then return
			if SERVER then -- Only on server
				if not ply:IsPlayingGesture( ply:GetSequenceActivity( seq ) ) then -- If players is not playing sequence, then force them to do so
					-- Removes all already playing gestures and adds found
					ply:RemoveAllGestures()
					ply:AddGestureSequence( seq, false )
				end
			end
			if ( ply:GetManipulateBonePosition( 0 ):IsZero() and ply:GetManipulateBoneAngles( 0 ):IsZero() ) or not SERVER then -- If player is not on the ground, play sequence
				return ply:GetSequenceActivity( seq ), seq
			end
			ply:ManipulateBonePosition( 0, vector_origin ) -- If on ground, rotate player back and play sequence
			ply:ManipulateBoneAngles( 0, angle_zero )
			return ply:GetSequenceActivity( seq ), seq
		end
	else -- Executes only if player is incapacitated
		if not SERVER then return end -- Only on server
		local seq = ply:LookupSequence( IncapMod.DeathSeq ) -- Try to find sequence
		if seq < 0 then return end -- If not found then return
		if not ply:IsPlayingGesture( ply:GetSequenceActivity( seq ) ) then return end -- If not playing sequence then return
		ply:RemoveGesture( ply:GetSequenceActivity( seq ) ) -- Remove played sequence
	end
end )

----[[ Interfaces ----]]
-- These hooks are for customization purposes. You can override them and even delete them (in which case value is reset to default one)

--[[ Hook "PlayerBlockRescue"
	arguments: (Player) rescuer - the player who initiated rescue; (Player) rescuant - the player who is required to be rescued
	return values: (bool) allows - return anything besides "nil" and "false" to prevent rescue 
Called when game needs to know when one player can rescue another player. Called clientside to determine if HUD element related should be drawn. Called serverside to determine if player can actually rescue other player
hook.Add( "PlayerBlockRescue", "identifier", function( rescuer, rescuant )
	return
end )

--[[ Hook "PlayerIncappedSpeed"
	arguments: (Player) ply - affected player
	return values: (number) speed - maximum amount of speed at which player can move
Called when player is incapacitated in order to determine at what speed player can move while incapacitated. Recommended to return same values both clientside and serverside
hook.Add( "PlayerIncappedSpeed", "identifier", function( ply )
	return 0
end ) --]]

-- Bottom text --
-- Haha funny totally not an old joke