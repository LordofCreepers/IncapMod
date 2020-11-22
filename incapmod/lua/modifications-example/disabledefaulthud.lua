-- This is example of how you can hide all elements of the IncapMod's default HUD
-- In order for this to work, put this file in "autorun/client" or
-- put "include( "modifications-example/disabledefaulthud.lua" )" at the top of any clientside file
-- (Which can be "cl_incapmod.lua", for instance)

local disabledhudelements_list = {
    [ "CHudIncapacityFlashings" ] = true, -- Hides frames around screen when player is incapaciated
    [ "CHudDeathMark" ] = true, -- Hides death skull that is drawn above incapped players
    [ "CHudRescuedStatus" ] = true, -- Hides text with rescuer and progress bar that showing rescue progress
    [ "CHudStandUpsStatus" ] = true, -- Hides text that tells how many "Stand-Ups" player has and how to use them
    [ "CHudPlayerCanRescue" ] = true, -- Hides text that appears when you're looking at player that can be rescued
    [ "CHudPlayerRescuing" ] = true -- Hides text with rescuant and progress bar that shows rescue progress
}

hook.Add( "HUDShouldDraw", "HideDefaultHud", function( el )
    if not disabledhudelements_list[ el ] then return end -- Doesn't return anything if element is not on list
    return false -- returns false, effectively disabling element
end )