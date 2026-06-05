hook_support_vigilant_aim = {}

register_blueprint "vigilant_aim"
{
	flags = { EF_NOPICKUP },
	text = {
		name = "Aim",
		desc = "accuracy is increased by given amount"
	},
	ui_buff = {
		color     = LIGHTCYAN,
		attribute = "aim_mod",
		priority  = 110,
	},
	attributes = {
		aim_mod   = 0,
		aim_decay = 1.0,
	},
	callbacks = {
		on_action = [[
			function ( self, entity, time_passed, last )
				if time_passed > 0 then
					-- nova.log("acting ...")
					local aim_mod   = self.attributes.aim_mod
					if aim_mod > 0 then
						local aim_decay = self.attributes.aim_decay
						local kcrap  = entity.target.entity
						if entity.data.ai.aimed_target ~= kcrap or not entity.data.ai.aware then
							entity.data.ai.aimed_target = nil
							self.attributes.aim_mod = 0
						end
						if last == COMMAND_REARM
						or ( aim_decay > 0 and last ~= COMMAND_WAIT )
						or not kcrap or not world:get_level():can_see_entity( entity, kcrap, 10 ) then
							entity.data.ai.aimed_target = nil
							self.attributes.aim_mod = 0
						end
						self.attributes.accuracy = self.attributes.aim_mod
					else
						self.attributes.accuracy = 0
					end
				end
			end
		]],
		on_wait = [[
			function ( self, entity )
				-- nova.log(" waiting ...")
				local kcrap = entity.target.entity
				if kcrap and not world:get_level():can_see_entity( entity, kcrap, 10 ) then
					kcrap = nil
				end
				entity.data.ai.aimed_target = kcrap
				if entity.data.ai.aimed_target and entity.data.ai.aware then
					local aim_bonus = entity:attribute( "aim_bonus" ) or 0
					self.attributes.aim_mod = math.min( self.attributes.aim_mod + 50 + aim_bonus, 100 )
				else
					self.attributes.aim_mod = 0
				end
			end
		]],
		on_move = [[
			function ( self, entity )
				-- nova.log(" moving ...")
				entity.data.ai.aimed_target = nil
				self.attributes.aim_mod = 0
			end
		]],
		on_aim = [=[
			function ( self, entity, target )
				-- nova.log(" aiming ...")
				local kcrap
				if target then kcrap = world:get_level():get_being( target ) end
				if kcrap and entity.data.ai.aimed_target == kcrap then
					self.attributes.accuracy = self.attributes.aim_mod
					-- nova.log ( "applying npc aim! "..(self.attributes.accuracy or 0) )
				else
					if entity.data.ai.aimed_target then
						-- nova.log ( "cancelling npc aim (old value: "..(self.attributes.aim_mod or 0)..")")
					end
					self.attributes.accuracy = 0
				end
			end
		]=],
	},
}

function hook_support_vigilant_aim.in_perks()
	local everything_ok = true
	local aim_callbacks = {"perk_wb_precise", "perk_ab_shotgun_focus", "perk_ab_auto_precise",
		"perk_ab_pistol_focus", "scope", "perk_we_tactical", "perk_we_precision"}
	for _, bp in ipairs( aim_callbacks ) do
		-- reusing Deemzul's recipe here as well... (see enemy_data/v_turret.lua for origins of the hack)
		if blueprints[bp] and blueprints[bp].callbacks and blueprints[bp].callbacks.on_aim then
			local s = blueprints[bp].callbacks.on_aim
			local n, nb = string.find( s, "entity:child(\"aim\")", 1, true )
			if nb then
				s = string.sub( s, 1, nb ).." or entity:child(\"vigilant_aim\")"..string.sub( s, nb+1 )
				blueprints[bp].callbacks.on_aim = s
			else
				everything_ok = false
				nova.warning(" blueprint on_aim intercept failed, ignoring "..bp)
			end
		else
			everything_ok = false
			nova.warning(" entry/target callback is missing, couldn't hook: "..bp)
		end
    end
    return everything_ok
end

function hook_support_vigilant_aim.run(self)
	if self.already then
        nova.warning("hook_support_vigilant_aim: attempt to run hook a second time")
        return
    end
    self.already = true
	local everything_ok = hook_support_vigilant_aim.in_perks()
	if everything_ok then
		nova.log(" hook_support_vigilant_aim has run successfully")
	else
		nova.warning(" hook_support_vigilant_aim has run, but there were issues")
	end
end

hook_support_vigilant_aim.run(hook_support_vigilant_aim)


-- regular hunker can be attached to enemies, but is bugged to show even when no cover
-- so try to make sure there is cover before activating
-- it still may not account for cover being destroyed, though
-- Upd: disabled because cover_mod doesn't seem to work against the player (?) investigate
register_blueprint "vigilant_hunker"
{
	flags = { EF_NOPICKUP },
	text = {
		name = "Hunker",
		desc = "cover effectiveness is increased by the given value"
	},
	ui_buff = {
		color     = LIGHTBLUE,
		attribute = "cover_mod",
		priority  = 100,
		style     = 6,
		defense   = true,
	},
	attributes = {
		cover_mod   = 0,
		cover_decay = 0.5,
	},
	callbacks = {
		on_action = [[
			function ( self, entity, time_passed, last )
				if time_passed > 0 then
					if not entity.data.ai.target_coord or not entity.data.ai.aware then
						self.attributes.cover_mod = 0
					end
					local cover_mod   = self.attributes.cover_mod
					local cover_decay = self.attributes.cover_decay
					if cover_mod > 0 and cover_decay > 0 then
						if last ~= COMMAND_WAIT then
							self.attributes.cover_mod = 0
						else
							self.attributes.cover_mod = cover_mod * cover_decay
						end
					end
				end
			end
		]],
		on_wait = [[
			function ( self, entity )
				local position  = world:get_position( entity )
				local target_coord = entity.data.ai.target_coord
				local level = world:get_level()
				local aware = entity.data.ai.aware
				if aware and target_coord and level:coord_see_entity( target_coord, entity, 10 )
					and level:get_max_cover( target_coord, position ) > 0.5 then
					self.attributes.cover_mod = 50
				end
			end
		]],
		on_move = [[
			function ( self, entity )
				self.attributes.cover_mod = 0
			end
		]],
	},
}
