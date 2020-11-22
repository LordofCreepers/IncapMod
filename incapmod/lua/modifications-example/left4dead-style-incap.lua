-- This is example of how Left 4 Dead style incapaciation can be done with IncapMod
-- In order for this to work, put this file in "autorun/server" or
-- put "include( "modifications-example/left4dead-style-incap.lua" )" at the top of any serverside file
-- (Which can be "sv_incapmod.lua", for instance)

hook.Add( "PlayerIncappedHealth", "SetHealthTo300", function()
    return 300
end )

hook.Add( "EntityTakeDamage", "ScaleDamageBy3", function( ent, dmginfo )
    if not ent:IsPlayer() then return end -- If damaged entity is not player, discard
    if not ent:IsIncapaciated() then return end -- If player is not incapaciated, discard
    dmginfo:ScaleDamage( 3 )
end )

hook.Add( "PlayerBleed", "Deal3DamageEverySecond", function()
    return 3
end )

hook.Add( "PlayerRescueRequiredTime", "identifier", function()
    return 5
end )