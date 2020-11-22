----[[ Code ----]]
-- Library initialization
IncapMod = IncapMod or {}
IncapMod.IncappedPlayers = IncapMod.IncappedPlayers or {}
IncapMod.SettingsEnum = IncapMod.SettingsEnum or { CSL_PRINTINCAP = 1, CSL_PRINTBLEEDING = 2, CSL_PRINTBLEEDOUT = 4, CSL_PRINTRESCUE = 8 }
IncapMod.SettingsDescriptions = IncapMod.SettingsDescriptions or { 
	CSL_PRINTINCAP = "Print in console when player is incapaciated",
	CSL_PRINTBLEEDING = "Print in console every time player takes damage due to bleedout",
	CSL_PRINTBLEEDOUT = "Print in console when player died due to bleedout",
	CSL_PRINTRESCUE = "Print in console when player is rescued"
}
--[[ W.I.P
IncapMod.Phrases = {
	Incapaciation = { Generic = { "Help!!!", "I'm down!", "I require assistance!", "I'm hurt!", "Agh!!! They got me!", "NO-O-O!!!", "Excuse me, I'm in need of medical attention!" }, ByPlayer = { "%s got me down!", "Get %s off of me!", "%s pinned me!" } },
	Rescue = { Generic = { "Thanks, man", "I thought I'm dead already! Thank you", "Thanks for saving me", "That was close", "I owe ya" }, ByPlayer = { "Thanks, %s", "Everyone, write down: I own %s a beer", "Oh, %s, I love you", "%s is always just in time" } }
} --]]
do
	local defaultConVarSettings_ArchiveRep = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
	IncapMod.Enabled = IncapMod.Enabled or CreateConVar( "incapmod_enabled", 1, defaultConVarSettings_ArchiveRep, "Whether IncapMod is enabled or not", 0, 1 )
	IncapMod.IncapHealth = IncapMod.IncapHealth or CreateConVar( "incapmod_healthonincap", 500, defaultConVarSettings_ArchiveRep, "Amount of health given to incapaciated players", 1 )
	IncapMod.MaxRescueDist = IncapMod.MaxRescueDist or CreateConVar( "incapmod_defaultmaxrescuedist", 100, defaultConVarSettings_ArchiveRep, "Default maximum distance at which player can be rescued", 1 )
	IncapMod.RescueDamageResetThreshold = IncapMod.RescueDamageResetThreshold or CreateConVar( "incapmod_rescuedmgresetthreshold", 0, defaultConVarSettings_ArchiveRep, "Maximum amount of damage that cannot affect rescue timer. If damage is above or equal to this value and player is rescued, rescue timer will be reset" )
	IncapMod.Bleedout = IncapMod.Bleedout or CreateConVar( "incapmod_bleedoutspeed", 5, defaultConVarSettings_ArchiveRep, 'Amount of health drained per second while incapaciated. Will take no effect if "PlayerBleed" hook return any value', 0 )
	IncapMod.PlayerRescueDefaultTime = IncapMod.PlayerRescueDefaultTime or CreateConVar( "incapmod_rescuetime", 5, defaultConVarSettings_ArchiveRep, 'Amount of time it takes to rescue player, in seconds. Will take no effect if "PlayerRescueRequiredTime" hook return any value' )
	IncapMod.OnlyTeammates = IncapMod.OnlyTeammates or CreateConVar( "incapmod_rescueteammatesonly", 1, defaultConVarSettings_ArchiveRep, 'When set to 1, players can only be rescued by their teammates', 0, 1 )
	--[[ W.I.P
	IncapMod.ChatScream = IncapMod.ChatScream or CreateConVar( "incapmod_autochatmessage", 0, defaultConVarSettings_ArchiveRep, "When set to 1, players automatically say some phrase from set of phrases in chat when incapaciated and rescued", 0, 1 )
	IncapMod.ScreamChance = IncapMod.ScreamChance or CreateConVar( "incapmod_screamchance", 4, defaultConVarSettings_ArchiveRep, 'Chance that player say some phrase from set of phrases. Calculated by formula: "1/value_of_this_variable"', 1 )
	IncapMod.TeamChatOnly = IncapMod.TeamChatOnly or CreateConVar( "incapmod_screamonlyinteamchat", 1, defaultConVarSettings_ArchiveRep, "When set to 1, player's phrases is only said in team chat", 0, 1 )
	--]]
	IncapMod.StartingStandUps = IncapMod.StartingStandUps or CreateConVar( "incapmod_playerstandupsonspawn", 0, defaultConVarSettings_ArchiveRep, 'How many "Stand-Ups" player has on respawn by default. Will take no effect if "GrantPlayerStandUps" hook return any value', 0 )
	IncapMod.MoveSpeed = IncapMod.MoveSpeed or CreateConVar( "incapmod_maxspeedwhileincapped", 0, defaultConVarSettings_ArchiveRep, 'What speed incapped players have. Will take no effect if "PlayerIncappedSpeed" hook return any value', 0 )
	IncapMod.MoveWhenRescued = IncapMod.MoveWhenRescued or CreateConVar( "incapmod_canmovewhilerescued", 0, defaultConVarSettings_ArchiveRep, "When set to 1, player can move while being rescued", 0, 1 )
	IncapMod.RestorePortion = IncapMod.RestorePortion or CreateConVar( "incapmod_healthportiontorestore", 0.3, defaultConVarSettings_ArchiveRep, 'Portion of health to restore when rescued. Will take no effect if "PlayerHealthRestoreOnUnincap" hook return any value', 0.05 )
	IncapMod.ShowDefaultHUD = IncapMod.ShowDefaultHUD or CreateConVar( "incapmod_showdefaulthud", 1, defaultConVarSettings_ArchiveRep, "When set to 1, shows default HUD of IncapMod", 0, 1 )
	IncapMod.XrayDeathMarks = IncapMod.XrayDeathMarks or CreateConVar( "incapmod_showdeathmarksthroughwalls", 0, defaultConVarSettings_ArchiveRep, 'When set to 1, shows death marks above incapaciated players heads through walls. If "incapmod_rescueteammatesonly" is set to 1, this feature will only work for teammates', 0, 1 )
	local settings_enum = settings_enum or IncapMod.SettingsEnum
	local settings_max = settings_max
	if not settings_max then
		local curnum = 0
		for setting, num in pairs( settings_enum ) do
			curnum = curnum + num
		end
		settings_max = curnum
	end
	local settings_enum_desc = settings_enum_desc or IncapMod.SettingsDescriptions
	local settings_desc = settings_desc
	if not settings_desc then
		settings_desc = ""
		for setting, desc in pairs( settings_enum_desc ) do
			settings_desc = settings_desc .. "	" .. settings_enum[ setting ] .. " (" .. setting .. ") - " .. desc .. "\n"
		end
	end
	local settings_default = settings_default or settings_max - settings_enum[ "CSL_PRINTBLEEDING" ]
	if SERVER then
		IncapMod.ConsoleSettings = CreateConVar( "incapmod_consolemessagesettings", settings_default, FCVAR_ARCHIVE, "Combination of bit settings which are applied to console prints of Incap mod. Possible values:\n" .. settings_desc, 0, settings_max )
	end
end
do
	local Player = FindMetaTable( "Player" )
	--[[ Function Player:IsIncapaciated()
		arguments: none
		return values: (bool) incapped - if player function is called on is incapaciated
	Checks if player is incapaciated --]]
	function Player:IsIncapaciated()
		return self:GetNWBool( "IsIncapped", false ) or tobool( IncapMod.IncappedPlayers[ self ] )
	end
	--[[ Function Player:GetCurrentlyRescuedPlayer()
		arguments: none
		return values: (Player) rescuant - player that is being rescued by the player function is called on
	Retrieves who is currently rescued by this player. Will be NULL Entity if player doesn't rescue anyone --]]
	function Player:GetCurrentlyRescuedPlayer()
		return self:GetNWEntity( "PlayerRescuing", NULL )
	end
	--[[ Function Player:GetRescuedBy()
		arguments: none
		return values: (Player) rescuer - player that is rescuing the player function is called on 
	Retrieves who is currently rescuing this player. Will be NULL Entity if no one rescues this player --]]
	function Player:GetRescuedBy()
		return self:GetNWEntity( "RescuingPlayer", NULL )
	end
	--[[ Function Player:RescueTimeLeft()
		arguments: none
		return values: (number) time - amount of time before the player will be rescued. This will be -1 if player is not rescued
	Returns time left, in seconds, until rescue should be completed --]]
	function Player:RescueTimeLeft()
		return ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueEndTime", 0 ) - CurTime() ) or -1
	end
	--[[ Function Player:StandUpsLeft()
		arguments: none
		return values: (number) amount of times player can stand up by himself before they will need to be rescued
	Gets amount of "Stand-Ups" --]]
	function Player:StandUpsLeft()
		return self:GetNWInt( "StandUpsLeft", 0 )
	end
	--[[ Function Player:GetMaxIncappedHealth()
		arguments: none
		return values: (number) health - amount of health that player got once was incapaciated
	If player is incapaciated, returns max health that player got when was incapaciated. Returns 0 if player is not incapaciated --]]
	function Player:GetMaxIncappedHealth()
		return self:GetNWFloat( "MaxIncappedHealth", 0 )
	end
	--[[ Function Player:GetRescueTimer()
	arguments: none
	return values: (number) start - start of rescue timer; (number) end - end of rescue timer
	Returns start and end of rescue timer, or 0, 0 if player is not rescued --]]
	function Player:GetRescueTimer()
		return ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueStartTime", 0 ) ) or 0, ( IsValid( self:GetRescuedBy() ) and self:GetNWFloat( "RescueEndTime", 0 ) ) or 0
	end
	--[[ Function Player:GetRescueTimeRatio()
	arguments: none
	return values: (number) ratio - gets ratio of start time and end time of rescue timer
	Returs ratio of start time and end time of rescue timer, from 0 (at start) to 1 (at end) --]]
	function Player:GetRescueTimeRatio()
		return ( CurTime() - self:GetNWInt( "RescueStartTime", 0 ) ) / ( self:GetNWInt( "RescueEndTime", 0 ) - self:GetNWInt( "RescueStartTime", 0 ) )
	end
end

-- Hook that runs every time player tries to change their weapons
hook.Add( "PlayerSwitchWeapon", "RestrictSwitchWeapons", function( ply, oldWep, newWep )
	if not IncapMod.Enabled:GetBool() then return end
	if ply:IsIncapaciated() and not tobool( IncapMod.AllowedWeapons[ newWep:GetClass() ] ) then return true end -- If player is incapaciated and wants to change weapons, reads from config and decides if player is actually allowed to change to this weapon
end )

-- Removes player from table of incapped players if he disconnects
gameevent.Listen( "player_disconnect" ) -- Runs every time player disconnects
hook.Add( "player_disconnect", "CleaningUpTheTable", function( data ) -- the same as above
	for _, p in ipairs( player.GetAll() ) do
		if p:UserID() ~= data.userid then continue end
		IncapMod.IncappedPlayers[ p ] = nil
		break
	end
end )

----[[ Interfaces ----]]
-- Table of weapons that is allowed to be held when player is incapaciated
IncapMod.AllowedWeapons = IncapMod.AllowedWeapons or {}
IncapMod.AllowedWeapons[ "weapon_pistol" ] = true
IncapMod.AllowedWeapons[ "weapon_357" ] = true

-- These hooks are for customization purposes. You can override them and even delete them (in which case value is reset to default one)

--[[ Hook "PlayerBlockRescue"
	arguments: (Player) rescuer - the player who initiated rescue; (Player) rescuant - the player who is required to be rescued
	return values: (bool) allows - return anything besides "nil" and "false" to prevent rescue 
Called when game needs to know when one player can rescue another player. Called clientside to determine if HUD element related should be drawn. Called serverside to determine if player can actually rescue other player
hook.Add( "PlayerBlockRescue", "identifier", function( rescuer, rescuant )
end )

--[[ Hook "PlayerIncappedSpeed"
	arguments: (Player) ply - affected player
	return values: (number) speed - maximum amount of speed at which player can move
Called when player is incapaciated in order to determine at what speed player can move while incapaciated. Recommended to return same values both clientside and serverside
hook.Add( "PlayerIncappedSpeed", "identifier", function( ply )
end ) --]]

-- Bottom text --
-- Haha funny totally not an old joke