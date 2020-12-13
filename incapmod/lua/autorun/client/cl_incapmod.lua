-- Released under GNU General Public License 3.0, 2 June 2007, Copyright (C) 2007 Free Software Foundation
-- Last changed: 13 December 2020

----[[ Code ----]]
-- Initializing variables
local incap_mat = incap_mat or nil
local incap_mat_pain = incap_mat_pain or nil
local almostblackbutalsotransparent = Color( 15, 15, 15, 245 )

IncapMod.Cvars.ShowDefaultHUDClient = IncapMod.Cvars.ShowDefaultHUDClient or CreateClientConVar( "incapmod_cl_showdefaulthud", 1, true, false, 'When set to 1, shows default HUD. "incapmod_showdefaulthud" has priority over this', 0, 1 )

do
	-- Creates materials that is used in default incapacity HUD
	hook.Add( "InitPostEntity", "CreateIncapMat", function()
		incap_mat = Material( "sprites/grad-incap.png" ) -- Inits "grad-incap" sprite
		incap_mat_pain = Material( "sprites/grad-incap-pain.png" ) -- Inits "grad-incap-pain" sprite
		deathskull_mat = Material( "sprites/death-skull.png" ) -- Inits "death-skull" sprite
		plain_arrow_mat = Material( "sprites/plain-arrow.png" )
	end )

	local nextFlashTime, lastFlashTime = SysTime() + 1, SysTime()
	local additive = true
	local function DrawPlayerOnIncapacitated() -- Draws black, red-flashing borders around the screen
		if not hook.Run( "HUDShouldDraw", "CHudIncapacityFlashings" ) then return end -- Doesn't run if "HUDShouldDraw" returns false
		surface.SetDrawColor( 0, 0, 0, 255 * ( 1 - LocalPlayer():Health() / LocalPlayer():GetMaxIncappedHealth() ) ) -- Set transparency depending on player's health
		surface.DrawRect( 0, 0, ScrW(), ScrH() )
		render.SetMaterial( incap_mat )
		render.DrawScreenQuad() -- Draws gradient across the screen
		surface.SetMaterial( incap_mat_pain )
		surface.SetDrawColor( 255, 255, 255, ( not additive and 255 * math.Clamp( ( SysTime() - lastFlashTime ) / ( nextFlashTime - lastFlashTime ), 0, 1 ) ) or 255 * ( 1 - math.Clamp( ( SysTime() - lastFlashTime ) / ( nextFlashTime - lastFlashTime ), 0, 1 ) ) ) -- Interpolates transparency over a second cooldown
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() ) -- Draws gradient across the screen
		if SysTime() > nextFlashTime then
			additive = not additive -- If cooldown is over, inverts additivity and resets cooldown depending on health
			nextFlashTime, lastFlashTime = SysTime() + math.Clamp( LocalPlayer():Health() / LocalPlayer():GetMaxIncappedHealth(), 0.15, 1 ), SysTime()
		end
	end

	-- Cached variables
	local angle_facing = Angle( 0, 0, 90 )
	local vector_height = Vector( 0, 0, 0 )
	local function RenderIncapacitatedPlayer( ply, rescuer, starttime, endtime ) -- Renders skull above incapacitated player
		if not hook.Run( "HUDShouldDraw", "CHudDeathMark" ) then return end -- Don't run if "HUDShouldDraw" return false
		local pos = ( ( IsValid( ply:GetActiveWeapon() ) and ply:GetPos() ) or ply:GetAttachment( ply:LookupAttachment( "chest" ) ).Pos )
		angle_facing.y = ( pos - EyePos() ):Angle().y - 90 -- Calculates direction towards LocalPlayer's camera
		vector_height.z = ( ply:GetCollisionBounds() ).z + 60 -- Calculates height of skull by adding 60 to height of collision bounds of player
		if IncapMod.Cvars.XrayDeathMarks:GetBool() and ( not IncapMod.Cvars.OnlyTeammates:GetBool() or LocalPlayer():Team() == ply:Team() ) then
			cam.IgnoreZ( true ) -- Renders skull through walls if "incapmod_showdeathmarksthroughwalls" is set to 1. Also, if "incapmod_rescueteammatesonly" is set to 1, only draws through walls for player's allies
		end
		cam.Start3D2D( pos + vector_height, angle_facing, 0.05 ) -- Starts 3D2D context
			surface.SetMaterial( deathskull_mat )
			surface.SetDrawColor( 55, ( IsValid( rescuer ) and 55 ) or 0, 0, 155 ) -- If player is being rescued, sets color to yellow. Sets color to red otherwise
			surface.DrawTexturedRect( -256, -256, 512, 512 ) -- Draws semi-transparent background skull
			surface.SetDrawColor( 255, ( IsValid( rescuer ) and 255 ) or 0, 0, 255 ) -- Sets color the same way as above, but opaque and brighter
			-- Draws bright foreground skull. If player is not being rescued, draws red skull from top to bottom, representing current health / maxincaphealth ratio. Otherwise draws yellow skull that goes from bottom to top representing the progress of rescue
			surface.DrawTexturedRectUV( -256, -256 + ( 512 - 512 * ( ( IsValid( rescuer ) and ( CurTime() - starttime ) / ( endtime - starttime ) ) or ( ply:Health() / ply:GetMaxIncappedHealth() ) ) ), 512, 512 * ( ( IsValid( rescuer ) and ( CurTime() - starttime ) / ( endtime - starttime ) ) or ( ply:Health() / ply:GetMaxIncappedHealth() ) ), 0, 1 - ( ( 512 * ( ( IsValid( rescuer ) and ( CurTime() - starttime ) / ( endtime - starttime ) ) or ( ply:Health() / ply:GetMaxIncappedHealth() ) ) ) / 512 ), 1, 1 )
		cam.End3D2D() -- Ends 3D2D context
		if IncapMod.Cvars.XrayDeathMarks:GetBool() and ( not IncapMod.Cvars.OnlyTeammates:GetBool() or LocalPlayer():Team() == ply:Team() ) then
			cam.IgnoreZ( false ) -- Inverts rendering through walls
		end
	end

	local function DrawPlayerIsRescued( rescuer, starttime, endtime ) -- Shows current player rescuing you and progress of rescue
		if not hook.Run( "HUDShouldDraw", "CHudRescuedStatus" ) then return end -- Don't run if "HUDShouldDraw" return false
		surface.SetFont( "TargetID" )
		surface.SetTextColor( team.GetColor( rescuer:Team() ):Unpack() ) -- Sets color to grey
		surface.SetTextPos( ScrW() * 0.5 - ( surface.GetTextSize( "You are being rescued by " .. rescuer:Nick() ) / 2 ), ScrH() * 0.65 ) -- Calculates size of text and adjusts it's position on screen
		surface.DrawText( "You are being rescued by " .. rescuer:Nick() ) -- Draws text mentioning player that rescues LocalPlayer
		local red = 255 * ( 1 - math.Clamp( ( CurTime() - starttime ) / ( endtime - starttime ), 0, 1 ) ) -- Caches red and green colors according to time remaining
		local green = 255 * math.Clamp( ( CurTime() - starttime ) / ( endtime - starttime ), 0, 1 )
		surface.SetDrawColor( red, green, 0, 155 )
		surface.DrawTexturedRect( ScrW() * 0.44, ScrH() * 0.7, ScrW() * 0.12, ScrH() * 0.2 ) -- Draws semi-transparent arrow as a background
		surface.SetDrawColor( red, green, 0, 255 )
		surface.DrawTexturedRectUV( ScrW() * 0.44, ScrH() * 0.7 + ( ScrH() * ( 0.2 - 0.2 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) ) ), ScrW() * 0.12, ScrH() * ( 0.2 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) ), 0, 1 - ( 320 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) / 320 ), 1, 1 ) -- Draws arrow as progress bar
	end

	local function DrawPlayerHasStandUps( amount, jumpkey ) -- Shows amount of "Stand-Ups" left and how player can use them. Is not called if none left
		if not hook.Run( "HUDShouldDraw", "CHudStandUpsStatus" ) then return end -- Don't run if "HUDShouldDraw" return false
		surface.SetFont( "TargetID" )
		surface.SetTextColor( team.GetColor( LocalPlayer():Team() ):Unpack() ) -- Sets color to grey
		surface.SetTextPos( ScrW() * 0.5 - ( surface.GetTextSize( "Press [" .. jumpkey .. "] to stand up by yourself" ) / 2 ), ScrH() * 0.65 ) -- Calculates size of text and adjusts it's position on screen
		surface.DrawText( "Press [" .. jumpkey .. "] to stand up by yourself" ) -- Draws text that tells player which button to press to stand up by themselves
		surface.SetTextPos( ScrW() * 0.5 - ( surface.GetTextSize( amount .. " times remains" ) / 2 ), ScrH() * 0.675 ) -- Calculates size of text and adjusts it's position on screen
		surface.DrawText( amount .. " times remains" ) -- Draws text showing amount of "Stand-Ups" left
	end

	local function DrawPlayerCanRescue( usekey, rescuant ) -- Shows player that they can unincap some player and tells how. Is not called if you're not looking at possibly rescuable player, too far, or don't meet conditions determined by "PlayerBlockRescue" hook
		if not hook.Run( "HUDShouldDraw", "CHudPlayerCanRescue" ) then return end -- Don't run if "HUDShouldDraw" return false
		surface.SetFont( "TargetID" )
		surface.SetTextColor( team.GetColor( rescuant:Team() ):Unpack() ) -- Sets color to grey
		surface.SetTextPos( ScrW() * 0.5 - ( surface.GetTextSize( "Hold [" .. usekey .. "] to start rescuing" ) / 2 ), ScrH() * 0.65 ) -- Calculates size of text and adjusts it's position on screen
		surface.DrawText( "Hold [" .. usekey .. "] to start rescuing" ) -- Draws text showing what button can player press to start rescuing other player
	end

	local function DrawPlayerRescuing( rescuant, starttime, endtime ) -- Shows who you're rescuing and progress of it. Is not called if you're not rescuing anyone
		if not hook.Run( "HUDShouldDraw", "CHudRescuing" ) then return end -- Don't run if "HUDShouldDraw" return false
		surface.SetFont( "TargetID" )
		surface.SetTextColor( team.GetColor( rescuant:Team() ):Unpack() ) -- Sets color to grey
		surface.SetTextPos( ScrW() * 0.5 - ( surface.GetTextSize( "You are rescuing " .. rescuant:Nick() ) / 2 ), ScrH() * 0.65 ) -- Calculates size of text and adjusts it's position on screen
		surface.DrawText( "You are rescuing " .. rescuant:Nick() ) -- Draws text mentioning player that LocalPlayer is currently rescuing
		surface.SetMaterial( plain_arrow_mat )
		local red = 255 * ( 1 - math.Clamp( ( CurTime() - starttime ) / ( endtime - starttime ), 0, 1 ) ) -- Caches red and green colors according to time remaining
		local green = 255 * math.Clamp( ( CurTime() - starttime ) / ( endtime - starttime ), 0, 1 )
		surface.SetDrawColor( red, green, 0, 155 )
		surface.DrawTexturedRect( ScrW() * 0.44, ScrH() * 0.7, ScrW() * 0.12, ScrH() * 0.2 ) -- Draws semi-transparent arrow as a background
		surface.SetDrawColor( red, green, 0, 255 )
		surface.DrawTexturedRectUV( ScrW() * 0.44, ScrH() * 0.7 + ( ScrH() * ( 0.2 - 0.2 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) ) ), ScrW() * 0.12, ScrH() * ( 0.2 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) ), 0, 1 - ( 320 * ( ( CurTime() - starttime ) / ( endtime - starttime ) ) / 320 ), 1, 1 ) -- Draws arrow as progress bar
	end
	-- Managing hud
	hook.Add( "HUDPaint", "DrawStuff", function()
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if not IncapMod.Cvars.ShowDefaultHUD:GetBool() or not IncapMod.Cvars.ShowDefaultHUDClient:GetBool() then return end
		if LocalPlayer():IsIncapacitated() then
			if IsValid( LocalPlayer():GetRescuedBy() ) then -- Runs "DrawPlayerIsRescued" if player is currently rescued
				DrawPlayerIsRescued( LocalPlayer():GetRescuedBy(), LocalPlayer():GetNWFloat( "RescueStartTime" ), LocalPlayer():GetNWFloat( "RescueEndTime" ) )
			elseif LocalPlayer():StandUpsLeft() > 0 then -- Runs "DrawPlayerHasStandUps" if player has stand-ups and not rescued
				DrawPlayerHasStandUps( LocalPlayer():StandUpsLeft(), string.upper( input.LookupBinding( "+jump" ) ) )
			end
		elseif IsValid( LocalPlayer():GetEyeTraceNoCursor().Entity ) and not IsValid( LocalPlayer():GetCurrentlyRescuedPlayer() ) then
			if not LocalPlayer():GetEyeTraceNoCursor().Entity:IsPlayer() then return end
			if not LocalPlayer():GetEyeTraceNoCursor().Entity:IsIncapacitated() or LocalPlayer():GetEyeTraceNoCursor().Entity:GetPos():DistToSqr( LocalPlayer():GetPos() ) > IncapMod.Cvars.MaxRescueDist:GetInt() ^ 2 or hook.Run( "PlayerBlockRescue", LocalPlayer(), LocalPlayer():GetEyeTraceNoCursor().Entity ) or ( LocalPlayer():Team() ~= LocalPlayer():GetEyeTraceNoCursor().Entity:Team() and IncapMod.OnlyTeammmates:GetBool() ) then return end
			DrawPlayerCanRescue( string.upper( input.LookupBinding( "+use" ) ), LocalPlayer():GetEyeTraceNoCursor().Entity ) -- Runs "DrawPlayerCanRescue" if local player see any incapacitated player in an apropriate distance, it meets conditions of "PlayerBlockRescue" and is in the same team, if "incapmod_rescueteammatesonly" set to 1
		elseif IsValid( LocalPlayer():GetCurrentlyRescuedPlayer() ) then -- Runs "DrawPlayerRescuing" if local player is currently rescuing any player
			DrawPlayerRescuing( LocalPlayer():GetCurrentlyRescuedPlayer(), LocalPlayer():GetCurrentlyRescuedPlayer():GetNWFloat( "RescueStartTime"), LocalPlayer():GetCurrentlyRescuedPlayer():GetNWFloat( "RescueEndTime") )
		end
	end )

	hook.Add( "HUDPaintBackground", "PaintIncapFrame", function() -- Runs "DrawPlayerOnIncapacitated" when player is incapacitated
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if not LocalPlayer():IsIncapacitated() then return end
		DrawPlayerOnIncapacitated()
	end )

	hook.Add( "PostPlayerDraw", "DrawPlayerAdditionalsOnIncap", function( ply ) -- Runs "RenderIncapacitatedPlayer" when player is incapacitated
		if not IncapMod.Cvars.Enabled:GetBool() then return end
		if not IsValid( ply ) then return end
		if not ply:IsIncapacitated() then return end
		RenderIncapacitatedPlayer( ply, ply:GetRescuedBy(), ply:GetNWFloat( "RescueStartTime", 0 ), ply:GetNWFloat( "RescueEndTime", 0 ) )
	end )
end

-- This hook repeats some actions of serverside hook in order for everything not to look glitchy clientside
hook.Add( "StartCommand", "RestrictPlayerMovement", function( ply, cmd )
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	ply.result_speed = hook.Run( "PlayerIncappedSpeed", ply ) or IncapMod.Cvars.MoveSpeed:GetFloat()
	if ply:IsIncapacitated() then -- Doesn't run if player is not incapacitated
		cmd:RemoveKey( IN_DUCK ) -- Disallows ducking while incapped
		if LocalPlayer():StandUpsLeft() <= 0 then
			cmd:RemoveKey( IN_JUMP ) -- If no "Stand-Ups" left, disallows jumping
		end
		if ply.result_speed <= 0 or ( not IncapMod.Cvars.MoveWhenRescued:GetBool() and IsValid( ply:GetRescuedBy() ) ) then
			cmd:ClearMovement() -- Stops all movement if player's speed while incapped is 0 or below and if player is rescued
		end
	elseif cmd:KeyDown( IN_USE ) and IsValid( ply:GetCurrentlyRescuedPlayer() ) then
		cmd:SetButtons( IN_USE ) -- If player is rescuing some player, forces holding use key and stops all movement
		cmd:ClearMovement()
	end
end )

hook.Add( "Think", "identifier", function()
	if not IsValid( LocalPlayer():GetCurrentlyRescuedPlayer() ) then return end
	error( "dummy error for not funny joke kill me", 1 )
end )

-- Hook that runs every time engine processes setup of player's movement
hook.Add( "SetupMove", "RestrictPlayerMove", function( ply, mv, cmd ) -- Also restricts movement. Required in case if player can move while incapped
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	if not ply:IsIncapacitated() then return end -- Doesn't run if player is not incapacitated
	if ply.result_speed <= 0 then return end -- Doesn't run if max player speed while incapped is 0 or below
	mv:SetMaxClientSpeed( ply.result_speed ) -- Restricts speed to max speed
end )

-- Cached variables
local viewdat = {}
local vec_down = Vector( 0, 0, -35 )
-- Hook that runs to check player's pov
hook.Add( "CalcView", "SetPlayer'sView", function( ply, pos, ang, fov )
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	if not ply:IsIncapacitated() then return end -- Doesn't run if player is not incapacitated
	viewdat.origin = pos + vec_down -- Lowers player's camera
	ang:RotateAroundAxis( ang:Forward(), 25 ) -- Tilts view a bit
	viewdat.angles = ang
	viewdat.fov = fov
	return viewdat
end )

-- Hook that runs to check player's viewmodel position
hook.Add( "CalcViewModelView", "OffsetViewModel", function( wep, vm, oldPos, oldAng, pos, ang ) -- Adjusts viewmodel position to correspond to "CalcView"'s result
	if not IncapMod.Cvars.Enabled:GetBool() then return end
	if not LocalPlayer():IsIncapacitated() then return end
	return pos + vec_down, ang -- Lowers viewmodel pos so it doesn't cause any glitches
end )