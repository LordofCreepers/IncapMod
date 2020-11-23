-- Released under GNU General Public License 3.0, 2 June 2007,  Copyright (C) 2007 Free Software Foundation
-- Last changed: 22 November 2020

-- This is example of how you can make incapped players take more explosive damage
-- Because, I think this one is good for balancing, I already put it in the bottom of "sv_incapmod.lua"
-- (You can find it - it's "include( "modifications-example/moreexplosivesdamage.lua" )")
-- You can freely remove it, it won't affect main code

hook.Add( "EntityTakeDamage", "ScaleExplosiveDamage", function( ent, dmginfo )
    if not ent:IsPlayer() then return end -- If damaged entity is not player, discard
    if not ent:IsIncapaciated() then return end -- If player is not incapaciated, discard
    if not dmginfo:IsExplosionDamage() then return end -- If damage is not explosive, discard
    dmginfo:ScaleDamage( 5 ) -- Multiplies damage by 5
end )