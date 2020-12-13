-- Released under GNU General Public License 3.0, 2 June 2007, Copyright (C) 2007 Free Software Foundation
-- Last changed: 22 November 2020

-- This is example how you can make your donators on server OP as hell. They can just destroy you... or... rather... just almost never die
-- In order for this to work, put this file in "autorun" or
-- put "include( "modifications-example/pay-to-win-strat.lua" )" at the top of any shared file
-- (Which can be "sh_incapmod.lua", for instance)

--[[ Modifiable properties:
    incap_health - amount of health on incap
    rescue_time - multiplicator of time required to rescue player
    rescue_time_scalar - multiplicator of time in what player can rescue other player
    bleeding - amount of bleeding
    dmgres - scalar of damage taken while incapped
    standups - stand-ups
--]]
local ranks_n_properties = {
    user = { -- This guy is a hobo. Or here for the first time. Long story short, we hate them here. Service is... what is even that?
        rescue_time_scalar = 99999
    },
    vip = { -- This guy isn't exactly rich, but he can get you a spare of 1-2$ per month or so. Service is... bearable
        rescue_time = 2.5,
        rescue_time_scalar = 2.5,
        standups = 1,
        speed = 25
    },
    donator = { -- This guy is dedicated to server. Not the best you can get, but way far from worst. 4-star restaurant service
        incap_health = 2500,
        bleeding = 2,
        rescue_time = 1,
        rescue_time_scalar = 1,
        dmgscale = 0.5,
        standups = 5,
        speed = 100
    },
    sponsor = { -- This guy has shit load of money. Even if vips and donators leave, sponsor will pull you out of the whole. He'd probably have anal sex with owner. 
        incap_health = 99999999,
        bleeding = 0,
        rescue_time = 0.1,
        rescue_time_scalar = 0.1,
        dmgscale = 0,
        standups = 99999,
        speed = 99999
    }
}

hook.Add( "PlayerIncappedSpeed", "RankUp", function( ply )
    return ranks_n_properties[ ply:GetUserGroup() ].speed    
end )

if not SERVER then return end

hook.Add( "PlayerBlockIncapacitation", "GimmeMoneyOrDi", function( ply )
    return ply:GetUserGroup() == "user" -- "user"s just die
end )

hook.Add( "PlayerIncappedHealth", "RankUp", function( ply )
    return ranks_n_properties[ ply:GetUserGroup() ].incap_health
end )

hook.Add( "PlayerBleed", "RankUp", function( ply )
    return ranks_n_properties[ ply:GetUserGroup() ].bleeding
end )

hook.Add( "PlayerRescueRequiredTime", "RankUp", function( rescuant, rescuer, isreset )
    return math.max( ( ranks_n_properties[ rescuant ].rescue_time - ranks_n_properties[ rescuant ].rescue_time_scalar ), 0.01 )
end )

hook.Add( "EntityTakeDamage", "RankUp", function( ent, dmginfo )
    if not ent:IsPlayer() then return end -- If damaged entity is not player, discard
    if not ent:IsIncapaciated() then return end -- If player is not incapaciated, discard
    dmginfo:ScaleDamage( ranks_n_properties[ ent:GetUserGroup() ].dmgscale or 1 )
end )

hook.Add( "GrantPlayerStandUps", "RankUp", function( ply )
    return ranks_n_properties[ ply:GetUserGroup() ].standups
end )