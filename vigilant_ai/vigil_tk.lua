nova.require "data/lua/core/aitk"
nova.require "libraries/bresenham"
nova.require "vigilant_ai/aim_npc"

-- utility class, also hosts default AI values for some of my extensions
vigil_tk = {
	camp_threshold = 12,
}

-- adds some perks to armor. does not check or respect mod cap
-- armor passed should be enemy armor, not supposed to be available to player
function vigil_tk.add_marksmanship_perks( armor, level, tier )
	local augment = {
		{ "perk_hb_long_tracking", "perk_cb_critical", },
		{ "perk_cb_critical", "perk_hb_crit_enhancer", "perk_hb_long_tracking", },
		{ "perk_cb_critical", "perk_hb_crit_enhancer", "perk_ha_target_tracking", },
	}
	local augment_level = tier or 0
	if level.level_info.depth > 25 and augment_level < 2 then
		augment_level = 2
	end
	if level.level_info.depth > 50 and augment_level < 3 then
		augment_level = 3
	end
	augment_level = math.clamp( augment_level, 1, math.clamp( DIFFICULTY, 1, 3) )
	--augment_level = 3 -- debug
	if augment_level < 3 then
		-- pick one perk
		local pwhat = math.random_pick( augment[augment_level] )
		armor:attach( pwhat, nil, nil )
	else
		-- level 3: pick 2 perks
		local pick = augment[augment_level]
		armor:attach( table.remove(pick, math.random( #pick ) ), nil, nil )
		armor:attach( table.remove(pick, math.random( #pick ) ), nil, nil )
	end
	-- and mandatory this, since have implemented aim logic
	armor:attach ( "perk_hb_aim_assist" )
end

-- creates an amp and makes entity equip it. entity is supposed to be non-player one;
-- so entry passed should be string for enemy amp, not supposed to be available to player
function vigil_tk.equip_amp_tier( self, level, entry, tier )
	tier = tier or 0
	local stage = level.level_info.episode or 0
	local depth = level.level_info.depth
	local min_tier = 1
	if stage >= 4 or depth > 25 then
		min_tier = 2
	end
	if depth > 99 then
		min_tier = 3
	end
	--min_tier = 3 -- debug
	-- amp can only be of 1--3 level
	tier = math.clamp( tier, min_tier, 3 )
	self:attach( world:create_entity( entry, tier ) )
end

function vigil_tk.attach_aim_hack( self )
	-- so base game does not really implement aim for enemies, let's roll our own implementation then
	return self:child( "aim" ) or self:child( "vigilant_aim" ) or self:attach ( "vigilant_aim" )
end

function vigil_tk.add_marksmanship_skills ( self )
	-- hunker should be safe to use on entities (unlike aim), but doesn't work correctly
	-- puts out values even when cover is absent. Tried to implement my own, but it seems
	-- cover_mod value is not being respected, so for now I don't add hunker to them.
	-- The attempt to find "hunker" on them already is merely for future versions of the
	-- game where it might, just might, have hunker and aim already attached to all entities
	-- capable of shooting. Native hunker and native aim on entities are not part of the game
	-- as of 1.8 (returns nil)
	local hunker = self:child( "hunker" ) --or self:child( "vigilant_hunker" ) or self:attach( "vigilant_hunker" )
	if hunker then
		hunker.attributes.cover_decay = 0.0
	end
	local aim = vigil_tk.attach_aim_hack( self )
	aim.attributes.aim_decay = 0.0
end

function vigil_tk.add_tank_perks( armor, level, tier )
	local augment = {
		{ "perk_cb_plated", "perk_cb_durable", },
		{ "perk_cb_plated", "perk_ae_onyx", "perk_ta_powered", },
	}
	local augment_level = (tier or 0) - 1
	if level.level_info.depth > 33 and augment_level < 1 then
		augment_level = 1
	end
	if level.level_info.depth > 66 and augment_level < 2 then
		augment_level = 2
	end
	if augment_level < 1 then
		return
	end
	augment_level = math.clamp( augment_level, 1, math.clamp( DIFFICULTY, 1, 2) )
	if augment_level < 2 then
		-- pick one perk
		local pwhat = math.random_pick( augment[augment_level] )
		armor:attach( pwhat, nil, nil )
	else
		-- pick 2 perks
		local pick = augment[augment_level]
		armor:attach( table.remove(pick, math.random( #pick ) ), nil, nil )
		armor:attach( table.remove(pick, math.random( #pick ) ), nil, nil )
	end
	if DIFFICULTY >= 3 and level.level_info.depth > 99 then -- Endless 100+
		-- third, non-randomized, perk
		-- redline catalyst is a rather weak perk, but we just add on top of what we have already
		armor:attach( "perk_ta_redline" , nil, nil )
	end
end

function vigil_tk.get_entity_opt_range( self, data, weapon )
	--local opt_distance = data.range or weapon.attributes.opt_distance or 5
	local opt_distance = self:attribute( "opt_distance", weapon.weapon.group )
	local range = data.range
	if range then
		for c in ecs:children(self) do
			if c.data and c.data.ai_buff then
				range = range + ( c:attribute( "opt_distance", weapon.weapon.group ) or 0 )
			end
		end
		-- presume shotguns's effective optimal range was hand-picked for non-AV variant, and
		-- increase it if AV rolls Calibrated 2 or similar. Avoid the double tally, though,
		-- if weapons begin to be marked ai_buff for some reason
		if weapon.attributes.opt_distance and not (weapon.data and weapon.data.ai_buff)
			and weapon.weapon.group == world:hash("shotguns") then
			-- Optimal distance including mods vs stock weapon's optimal distance
			local diff = (weapon:attribute( "opt_distance", weapon.weapon.group) or 0) - weapon.attributes.opt_distance
			if diff > 0 then
				range = range + diff
				--nova.log("(apparently) calibrated shotgun: increasing ai range by "..diff..", resulting ai range="..range)
			end
		end
	end
	if range and range > (opt_distance or 0) then
		--nova.log( "weapon opt: "..opt_distance.." is smaller than AI range: "..range.." for entity "..self.text.name )
		opt_distance = range
	else
		--if data.range and data.range < (opt_distance or 0) then
		--	nova.log( "weapon opt: "..opt_distance.." is greater than AI range: "..range.." for entity "..self.text.name )
		--end
		--if data.range and data.range == (opt_distance or 0) then
		--	nova.log( "weapon opt: "..opt_distance.." is equal to AI range: "..range.." for entity "..self.text.name )
		--end
	end
	if not opt_distance then
		-- default value same as in base game aitk
		opt_distance = 5
	end
	return opt_distance
end

function vigil_tk.unobstructed_path_no_cover(level, coord_from, coord_to)
	local smth = los(coord_from.x, coord_from.y, coord_to.x, coord_to.y, function(x,y)
			local f = level:get_cell_flags( coord.new( x, y ) )
			if f and ( f[EF_NOSHOOT] or f[EF_NOSIGHT] or f[EF_HARD_COVER] ) then
				-- shot obstructed or considered low success
				-- that is, might count hard cover as blocking shots altogether even
				-- if it is not
				return false
			end
			return true
		end)
	return smth
end

-- Weapons that are permitted speculative fire are those that can be
-- reasonably fired through smoke, etc. indirect fire weapons or shotguns
function vigil_tk.can_speculatively_fire(level, weapon, coord_from, coord_to)
	local w = weapon
	return w.weapon and (w.weapon.type == world:hash("mortar") or
		w.weapon.group == world:hash("shotguns")) and
		vigil_tk.unobstructed_path_no_cover(level, coord_from, coord_to)
end

function vigil_tk.attack_through_heat_vision(self, level, data, weapon, dist)
	if data.heat_vision and not data.heat_vision.attack_through then
		return nil
	end
	local w = weapon
	if w.weapon and w.weapon.type ~= world:hash("melee") then
		local opt_distance = vigil_tk.get_entity_opt_range(self, data, weapon)
		local target_coord = world:get_position( self.target.entity )
		local self_coord = world:get_position( self )
		if dist <= opt_distance then
			local chance = data.fire_ch_base or 40
			local low_accuracy = false
			local allow = vigil_tk.can_speculatively_fire(level, weapon, self_coord, target_coord)
			if not allow then
				-- might be having a weapon not well suited to the task. But if target (usually
				-- player) has stealth rather than there is a smoke/gas cloud obstructing them,
				-- heatvision should still reveal their body shape
				-- Note: using a hack to see us (npc) from target's point of view. This one
				-- WILL be blocked by smoke, however, hence why above I used a new function
				-- which does not have that limitation
				allow = level:coord_see_entity( target_coord, self, opt_distance )
				if allow then
					-- they might be in hard cover
					-- data.long_miss_penalty is reused here merely so that tuning stats are
					-- not too many. Otherwise, its primary purpose is in main vigilant_hunt:
					-- to lower chance when shooting beyond optimal range
					chance = chance + (data.long_miss_penalty or 0)
					low_accuracy = true
				end
			end
			if not allow then -- clearly obstructed
				return nil
			end
			if not low_accuracy then
				local ch_mod = data.fire_ch_mod or 10
				chance = chance + math.min( DIFFICULTY, 2 ) * ch_mod
			end
			local attack = math.random(100) <= chance
			if attack then
				local result = aitk.run_state( self, "do_attack", data, nil, weapon )
				if result then return result end
				return "hunt"
			end
		end
	end
end

-- part of new hunt state handler logic, separated into new method for readability
-- prolongs hunt state when target gets out of direct vision
-- if returns state, it must be returned further
-- if returns nothing, only then caller can do something else
function vigil_tk.extend_hunt( self, level, data, weapon )
	-- currently hold_position is not much compatible with heat_vision

	if data.target_coord and data.hold_position then
		local position	= world:get_position( self )
		-- check if position is actually bad
		for e in level:entities( position ) do
			-- TODO need implement check: we might actually be immune to this hazard
			if e.hazard then
				-- no camping here
				data.camp = vigil_tk.camp_threshold + 1
				-- hopefully moves us away
				local result = vigil_tk.guard_avoid_hazards( self, data, "hunt" )
				if result then return result end
				-- was not successful in avoiding, dash in desperation towards
				-- the enemy
				data.alert = 0
				if self.listen then self.listen.active = true end
				world:command_coord( COMMAND_MOVE, self, data.target_coord )
				return "seek"
			end
		end

		-- only stay for limited time
		if data.camp and data.camp > vigil_tk.camp_threshold then
			data.camp = 0
			data.target_coord = nil
		else
			data.camp = data.camp or 0
			if data.camp == 0 then -- shorten "glued post" by random amount
				data.camp = math.random(5)
			else
				data.camp = data.camp + 1
				if data.camp == 0 then -- was set to negative value; signals annoyance
					data.camp = 1 -- punish player by not shortening the stay
				end
			end
			local entrenched = level:get_max_cover( data.target_coord, position ) > 0.5
			 if entrenched then -- maintaining our vigil in this position
				world:command( COMMAND_WAIT, self )
				return "hunt"
			end
		end
	end

	if self.target.entity and level:is_alive( self.target.entity ) and data.heat_vision then
		local dist = level:distance( self, self.target.entity )
		if dist <= (data.heat_vision.range or data.range or 3) then
			data.target_coord = world:get_position( self.target.entity )
			if not data.no_reload then
				local result = vigil_tk.attack_through_heat_vision(self, level, data, weapon, dist)
				if result then return result end
			end
			-- otherwise just move toward target if possible (even through hazards ??)
			-- I guess avoiding hazards in chase mode would require some smart logic
			world:command_coord( COMMAND_MOVE, self, data.target_coord )
			return "hunt"
		end
	end
end

function vigil_tk.melee_to_bypass_reload( self, data, weapon )
	if data.mortar or data.charged or data.charging then
		-- attack modes with their own logic
		data.shoot_unless_empty = false
		return false
	end

	local w = weapon
	local ranged = w and w.weapon and w.weapon.type ~= world:hash("melee")
	if not ranged then
		return false
	end

	if w.weapon.type == world:hash("mortar") then
		-- don't bother (ranged attack is spread over multiple turns)
		data.shoot_unless_empty = false
		return false
	end

	local level = world:get_level()
	if not level:is_alive( self.target.entity ) then
		return false
	end

	local cd   = w.clip
	if cd and cd.count == 0 then
		if level:can_see_entity( self, self.target.entity, data.vision or 8 ) then
			local dist = level:distance( self, self.target.entity )
			local melee = data.melee or 0
			-- crap to kill (enemy, like player, for example)
			local kcrap_pos = world:get_position( self.target.entity )
			if dist < 3 and melee > 0 and level:can_melee( self, kcrap_pos ) then
				data.target_coord = kcrap_pos
				world:command_use( COMMAND_USE, self, world:get_weapon_by_type( self, true ), kcrap_pos )
				return true
			end
		end
	end
	return false
end

-- "vigilant" upgrade/replacement for hunt state. Modified from original (c) ChaosForge Sp. z o.o.
-- requires seek and idle
function aitk.vigilant_hunt ( self )
	local weapon = aitk.get_ranged( self )
	local data	= self.data.ai
	local level = world:get_level()

	if data.shoot_unless_empty and vigil_tk.melee_to_bypass_reload( self, data, weapon ) then
		return "hunt"
	end
	if weapon and aitk.do_reload( self, weapon ) then
		return "hunt"
	end
	if data.no_reload then
		-- human enemies can run out of ammo?!!
		-- and no_reload meant exactly this condition all along, rather than "don't need ammo to reload"?!!
		-- I wasted whole day making sense of this and the lack of Hunker/Aim for enemies (and how to implement it)
		data.hold_position = false -- useless to camp, run and punch instead
		data.shoot_unless_empty = false -- no reason to bypass either, reload does not succeed nor waste turn
	end

	if data.mortar then
		local result = aitk.run_state( self, "do_attack", data, data.target_coord, weapon )
		if result then return result end
		return "hunt"
	end

	if not level:is_alive( self.target.entity ) then
		self.target.entity = aitk.pick_target( self )
		data.camp = 0
	elseif data.hold_position and data.aware and not level:can_see_entity( self, self.target.entity, data.vision or 8 ) then
		local alt_target = vigil_tk.marksman_pick_target( self, level, data )
		if alt_target and level:can_see_entity( self, alt_target, data.vision or 8 ) then
			self.target.entity = alt_target
			-- but don't reset camp (will soon be reset anyway)
		end
	end

	if data.charged and level:can_see_entity( self, self.target.entity, data.vision or 8 ) then
		local result = aitk.run_state( self, "do_attack", data, nil, weapon )
		if result then return result end
		return "hunt"
	end

	if data.charging or level:can_see_entity( self, self.target.entity, data.vision or 8 ) then
		data.camp = 0
		data.target_coord = world:get_position( self.target.entity )
		local move		= data.target_coord
		local melee		= data.melee or 0
		local no_reload = data.no_reload or false
		local position	= world:get_position( self )

		if data.charging then
			local charge   = data.charging
			ui:telegraph( self )
			ui:telegraph( self )
			data.charging = nil
			local target = level:get_being( position + charge )
			if not target then
				local cmove	 = level:try_move( self, position + charge, true )
				if cmove > 0 and position + charge ~= move then
					target = level:get_being( position + charge + charge )
					if not target then
						level:try_move( self, position + charge + charge, true )
					end
				end
			end
			if target then
				world:command_use( COMMAND_USE, self, world:get_weapon_by_type( self, true ), move )
			else
				world:command( COMMAND_WAIT, self )
			end
			self.attributes.crit_chance = 0
			return "hunt"
		end

		local dist = level:distance( self, self.target.entity )

		if not data.shoot_unless_empty and dist < 3 and melee > 0 and level:can_melee( self, data.target_coord ) then
			world:command_use( COMMAND_USE, self, world:get_weapon_by_type( self, true ), move )
			return "hunt"
		end

		local attack = false
		local advance = false
		local aim = false
		if not no_reload and weapon then
			attack = ( dist < 2 )
			if not attack and data.aware and dist < 3 and melee < 2 then
				local target_cover = level:get_max_cover( position, data.target_coord )
				if melee > 0 and target_cover > 0.4 then
					advance = true
				else
					attack = true
				end
			end
			if not attack and data.aware then
				local cover = data.cover
				local opt_distance = vigil_tk.get_entity_opt_range(self, data, weapon)
				local max_distance = data.max_range or 8

				local chance = data.fire_ch_base or 40
				if dist <= opt_distance or ( self:attribute("accuracy") or 0 >= 100 ) then
					chance = chance + 20
					if not cover then
						local ch_mod = data.fire_ch_mod or 10
						chance = chance + math.min( DIFFICULTY, 2 ) * ch_mod
					end
				else -- another novelty feature of mine to make shotgunners good
					if data.long_miss_penalty then
						local target_cover = level:get_max_cover( position, data.target_coord )
						if target_cover > 0.3 then
							-- long_miss_penalty should be negative value
							chance = chance + data.long_miss_penalty
						end
					end
				end

				if dist > max_distance then
					cover  = false
					chance = 0
				end

				attack = math.random(100) <= chance
				if not attack and cover and not advance then
					if data.hold_position then -- marksman ai override
						local dir  = vigil_tk.marksman_pick_dir( self, data, opt_distance )
						if dir then
							move = world:get_position( self ) + dir
						else
							-- one rationale for having npcs aim is that I found they *can*
							-- run out of ammo. Which, for reluctant-to-close-distance npcs,
							-- can happen a bit more often
							aim = vigil_tk.can_increase_aim( self, weapon )
							if not aim then
								attack = true
							end
						end
					else -- default ai just like aitk.hunt
						local dir  = aitk.pick_dir( self, data )
						if dir then
							move = world:get_position( self ) + dir
						else
							attack = true
						end
					end
				end
			end
		end

		if attack then
			data.aware = true
			local result = aitk.run_state( self, "do_attack", data, data.target_coord, weapon )
			if result then return result end
		else
			local surprise = aim or (weapon and dist < 3 and not data.aware)
			if not surprise and not data.aware and data.hold_position then
				local dir = vigil_tk.marksman_pick_dir( self, data, vigil_tk.get_entity_opt_range(self, data, weapon) )
				if dir then
					move = world:get_position( self ) + dir
				else
					surprise = true
					data.camp = -2 -- if position happens to provide good cover but player flees battle, annoy player by camping in it longer than usual
				end
			end
			if surprise then
				-- might automatically hunker and/or aim, if applicable
				world:command( COMMAND_WAIT, self )
			else
				world:command_coord( COMMAND_MOVE, self, move )
			end
		end

		if data.charge then
			local position = world:get_position( self )
			local relative = data.target_coord - position
			if relative.x * relative.y == 0 then
				if math.abs( relative.x ) == 2 or math.abs( relative.y ) == 2 then
					local step = coord( relative.x / 2, relative.y / 2 )
					if level:can_move( self, position + step, false, true ) then
						data.charging = step
						local color = tcolor( RED, vec4( 0.5, 0.2, 0.0, 1.0 ) )
						ui:telegraph( self, position + step, "ui_charge_03", color )
						ui:telegraph( self, position + step + step,	 "ui_charge_03", color )
						self.attributes.crit_chance = 100
					end
				end
			end
		end

		data.aware = true
		return "hunt"
	else
		-- new capabilities for enemies: camping, heatvision etc.
		local result = vigil_tk.extend_hunt( self, level, data, weapon )
		if result then
			return result
		end

		if self.listen then self.listen.active = true end
		if data.target_coord then
			world:command_coord( COMMAND_MOVE, self, data.target_coord )
			return "seek"
		else
			data.alert = 1
			world:command( COMMAND_WAIT, self )
			return "idle"
		end
	end
end

function vigil_tk.marksman_evaluate_dir( self, level, data, dir, opt_range )
	local coord = world:get_position( self )
	if dir then
		coord = coord + dir
		if not level:can_move( self, coord, true, true ) then return -2 end
	end
	for e in level:entities( coord ) do
		if e.hazard then
			return -1
		end
	end
	local target = self.target.entity
	if not target or not level:coord_see_entity( coord, target, data.vision or 8 ) then return 0 end
	local tpos	 = world:get_position( target )
	local cover	 = level:get_max_cover( tpos, coord ) -- our own cover against them
	if cover > 0 then return math.ceil( cover * 100 ) end
	local penalty = 0
	local dist = math.ceil( level:cdistance( tpos, coord ) )
	if dist > opt_range or level:get_max_cover( coord, tpos ) > 0.3 then -- *their* cover against us
		penalty = dist
	end
	return 20 - penalty
end

function vigil_tk.marksman_pick_dir( self, data, opt_range )
	local result
	local level	 = world:get_level()
	local best	 = vigil_tk.marksman_evaluate_dir( self, level, data, nil, opt_range )
	if not data.aware and best > 0 then -- less likely to move (have allies approach instead)
		best = best + 10
	end
	for i,dir in ipairs( aitk.dirs ) do
		local value = vigil_tk.marksman_evaluate_dir( self, level, data, dir, opt_range )
		if value > best then
			result = dir:clone()
			best   = value
		end
	end
	return result -- nil if no move
end

function vigil_tk.can_increase_aim ( self, weapon )
	local w = weapon
	local result = w.weapon and not (w.weapon.type == world:hash("mortar") or
		w.weapon.group == world:hash("shotguns"))
	if result then
		result = self:child( "aim" ) or self:child( "vigilant_aim" )
	end
	return result and result.attributes.aim_mod < 100
end

-- avoid hazards while remaining near post. Based on aitk.stagger,
-- reworked for hold_position/hunt scenario.
-- returns either next_state (if successful, move has occurred)
-- or nil (hazards can't be avoided, move has NOT occurred)
function vigil_tk.guard_avoid_hazards( self, data, next_state )
	local level = world:get_level()
	local ar    = data.area or level:get_area()

	local check_coord = function( c )
		if not level:can_move( self, c, true, true ) then
			return -3
		end
		for e in level:entities( c ) do
			if e.hazard then
				return -2
			end
		end
		if c.x > ar.b.x then return -1 end
		if c.x < ar.a.x then return -1 end
		if c.y > ar.b.y then return -1 end
		if c.y < ar.a.y then return -1 end
		return 0
	end

	local rolls = {1,2,3,4}
	local p     = world:get_position( self )
	local best
	local best_value = -3
	repeat
		local roll = table.remove( rolls, math.random(#rolls) )
		local c = p + aitk.dirs[roll]
		local chk = check_coord( c )
		if chk == 0 then
			world:command( COMMAND_MOVE, self, c )
			return next_state
		elseif chk > best_value then
			best_value = chk
			best = c
		end
	until #rolls == 0
	if best and best_value > -2 then
		world:command( COMMAND_MOVE, self, best )
		return next_state
	end
	return nil
end

function vigil_tk.marksman_pick_target( self, level, data )
	local p = world:get_position( self )
	local tcoord = data.target_coord
	if tcoord and not level:coord_see_entity( tcoord, self, data.vision or 8) then
		-- hack. Trying to see self from coord's perspective. Will fail if sight
		-- obscured (smoke, etc.)
		tcoord = nil
	end
	local rate = function( kcrap )
		local pcrap = world:get_position( kcrap )
		-- closest to original target
		if tcoord and level:can_see_entity( self, kcrap, data.vision or 8 ) then
			return 600 - math.ceil( level:cdistance( pcrap, tcoord ) )
		end
		-- closest to self
		local base_score = 300
		if not level:can_see_entity( self, kcrap, data.vision or 8 ) then
			base_score = 150
		end
		return base_score - math.ceil( level:cdistance( pcrap, p ) )
	end

	local best
	local best_score = 0

	for kcrap in level:targets( self ) do
		if aitk.is_enemy( self, kcrap ) == 1 then
			local score = rate( kcrap )
			if score > best_score then
				best_score = score
				best = kcrap
			end
		end
	end
	return best
end
