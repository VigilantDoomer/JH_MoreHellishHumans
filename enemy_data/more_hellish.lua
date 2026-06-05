nova.require "data/lua/core/common"
nova.require "data/lua/core/aitk"
nova.require "data/lua/core/utility"
nova.require "data/lua/jh/data/gtk"
nova.require "data/lua/jh/data/common"
nova.require "data/lua/jh/data/entities/security"
nova.require "data/lua/jh/data/items/ammo"
nova.require "data/lua/jh/data/weapons/pistol"
nova.require "data/lua/jh/data/weapons/auto"
nova.require "data/lua/jh/data/weapons/semi"
nova.require "data/lua/jh/data/weapons/chaingun"
nova.require "data/lua/jh/data/weapons/launcher"
nova.require "data/lua/jh/data/weapons/revolver"
nova.require "data/lua/jh/data/weapons/shotgun"
nova.require "data/lua/jh/data/weapons/saw"
nova.require "vigilant_ai/vigil_tk.lua"

-- Hellish marksmen and skirmishers conceptually supersede hellish grunts and guards
-- (but don't replace existing blueprints).
-- Hellish sergeant major is an effective shotgun threat for once.

-- Note: IO Black Site also uses "beyond" enemy list.
-- Purity and Haste deliberately exclude all formers and bots in Beyond, so won't spawn
-- these either.
-- Non-beyond spawns are intended for completionist trial, and possibly endless/gauntlet
-- or similar trials.

-- "kevlar" is codename for "infantry light armor"
register_blueprint "vigilant_kevlar"
{
	flags = { EF_NOPICKUP },
	armor = {},
	attributes = {
		armor = {
			3,
			slash  = 3,
			pierce = -1,
			plasma = -1,
		},
		health	 = 28,
	},
	data = {
		ai_buff = true, -- see vigilant_amp_pistol for what this parameter does
	},
	health = {},
}

-- "plate" is codename for "infantry heavy armor"
register_blueprint "vigilant_plate"
{
	flags = { EF_NOPICKUP },
	armor = {},
	attributes = {
		armor = {
			6,
			slash  = 6,
			pierce = -3,
			plasma = -3,
		},
		health	     = 42,
		crit_defence = 100,
	},
	data = {
		ai_buff = true,
	},
	health = {},
}

-- pistol amp for these fine gentlemen from hell, not for player
register_blueprint "vigilant_amp_pistol"
{
	flags = { EF_NOPICKUP },
	text = { -- must have text.name or will crush generator.roll_perks (internally name is prepended by AV tier)
		name = "pistol AMP",
		desc = "Advanced utility device for use with pistols, SMGs and revolvers. Properties vary.",
	},
	data = {
		perk = {
			type	 = "perk_c",
			subtype	 = "amp",
			subtype2 = "pistol",
			mod		= { reload = 0 }
		}, -- tested utility AMP, it did work (movement speed increase visible when rolling metabolic boost), so presumably pistol/smg amps work too
		--perk = {
		--	type	= "perk_c",
		--	subtype = "amp",
		--	mod		= { pistol = 0, shotgun = 0, auto = 0, melee = 0, scout = 0, marine = 0, healing = 0, tech = 0 }
		--},

		-- vigil_tk extension "ai_buff": designates that ai should look into rolled perks, for example, apply optimal range bonus to entity.data.ai.range
		-- note this doesn't mean that it only works for ai. It works like a normal amp, what is added by this, is that vigil_tk ai code will check child
		-- perks to see if there is something useful
		ai_buff = true,
	},
	callbacks = {
		on_create = [=[
			function(self,_,tier)
				generator.roll_perks( self, tier )
			end
		]=],
	},
}

-- Lightly armored troop, pistols + accuracy
register_blueprint "v_marksman0"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ 2, keywords = { "beyond", "former", "former3", "civilian" }, weight = 100, dmax = 19, },
		{ 3, keywords = { "europa", "beyond", "former", "former3", "swarm", "civilian" }, weight = 70, dmin = 20, },
		{ { { "v_marksman0", tier = 2 }, "v_marksman0", "v_marksman0", }, keywords = { "beyond", "former", "former3", "civilian" }, weight = 50, dmin = 18, },
		{ { { "v_marksman0", tier = 3 }, "v_marksman0", "v_marksman0", }, keywords = { "io", "beyond", "former", "former3", "civilian" }, weight = 20, dmin = 40, },
		{ 2, keywords = { "callisto", "former", "former3", "civilian" }, weight = 100, dmin = 14, }, -- completionist and any long random modes
	},
	ascii	  = {
		glyph	  = "h",
		color	  = LIGHTCYAN,
	},
	text  = {
		name  = "hellish marksman",
		namep = "hellish marksmen",
	},
	callbacks = {
		on_create = [=[
		function( self, level, tier )
			if tier > 1 then
				make_weapon_entry( self, { "adv_lpistol", "ammo_44", 8, tier = tier - 1 } )
			else
				make_weapon( self, level, {
					{ "energy_pistol","ammo_cells", 8,	weight = 6, min_depth = 21, },
					-- as much as I like two-shot accuracy with 7.62 sidearm, in Endless,
					-- this ammo would keep AWP fed even prior finding nano or sustain pack
					-- also can't decrease ammo found, because else they can run out of it
					{ "apistol",	  "ammo_762",  10,	weight = 7, min_depth = 4, max_depth = 21, },
					{ "apistol",	  "ammo_762",  12,	weight = 2, min_depth = 22, },
					{ "lpistol",	  "ammo_44",   10,	weight = 3, min_depth = 3,	},
					{ "bpistol",	  "ammo_9mm",  14,	weight = 4, max_depth = 6,	},
				})
			end

			local apiece = self:attach( "vigilant_kevlar" )
			if level.level_info.low_light then
				self:attach( "npc_flashlight" )
			end
			vigil_tk.add_marksmanship_perks( apiece, level, tier )
			vigil_tk.add_marksmanship_skills( self )
			vigil_tk.equip_amp_tier( self, level, "vigilant_amp_pistol", tier )
		end
		]=],
	},
	attributes = {
		speed			 = 1.0,
		move_time		 = 0.9,
		experience_value = 25,
		accuracy		 = 20,
		health			 = 50,
		crit_chance      = 15, -- always some chance to crit
	},
	data = {
		ai = {
			hunt			   = "vigilant_hunt",
			range			   = 5,
			hold_position	   = true, -- when target disengages, keep good post *if* found one / other logic (support aiming, etc.)
		},
	},
}

-- heatvision + stabilized 2 buff for high-tier shotgunner
-- Red light works better with dark purple than green (Nightvision) would
-- Also: buff only technically gives the max distance boost, the Heatvision ability needs to be
-- coded on entity itself. It doesn't have graphics either
register_blueprint "buff_vigilant_stalker"
{
	flags = { EF_NOPICKUP },
	text = {
		name  = "Heatvision",
		desc  = "Can track targets through stealth, smoke and walls, +2 to max weapon range",
	},
	attributes = {
		max_distance = 2,
	},
	ui_buff = {
		color = LIGHTBLUE,
	},
	callbacks = {
		on_die = [=[
			function( self )
				world:mark_destroy( self )
			end
		]=],
	},
}

-- Hardcore hellish sergeant major, does not use flashlight in low light, because uses heatvision instead.
-- Heavily armored, yet can run some (veterancy = awesomeness)
register_blueprint "v_sergeant0"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ keywords = { "beyond",  "former", "former3", "civilian" }, weight = 30, },
		{ { { "v_sergeant0", tier = 2 }, "v_marksman0", "v_marksman0", } ,
			keywords = { "callisto", "beyond", "pack", "former", "former3", "civilian" }, weight = 75, dmin = 22, },
		{ { { "v_sergeant0", tier = 3 }, "v_marksman0", "v_marksman0", "soldier3", } ,
			keywords = { "callisto", "europa", "beyond", "pack", "former", "former3", "civilian" }, weight = 45, dmin = 24, },
		{ keywords = { "callisto",	"former", "former3", "civilian" }, weight = 30, dmin = 14, }, -- completionist and any long random modes
		{ { { "v_sergeant0", tier = 3 }, "v_marksman0", "v_marksman0", "soldier3", }, -- ditto
			keywords = { "io", "former", "former3", "civilian" }, weight = 30, dmin = 40, },
	},
	ascii	  = {
		glyph	  = "h",
		color	  = LIGHTRED,
	},
	text = {
		name	  = "hellish sgt. major",
		namep	  = "hellish sgt. majors",
	},
	callbacks = {
		on_create = [=[
		function( self, level, tier )
			if tier > 1 then
				make_weapon_entry( self, { "adv_dshotgun", "ammo_shells", 20, tier = tier - 1 } )
			else
				make_weapon( self, level, {
					{ "energy_shotgun", "ammo_cells",  16, weight = 4, min_depth = 21, },
					{ "dshotgun",		"ammo_shells", 16, weight = 6, min_depth = 9, },
					{ "ashotgun",		"ammo_shells", 16, weight = 5, },
				})
			end
			local apiece = self:attach( "vigilant_plate" )
			vigil_tk.add_tank_perks( apiece, level, tier )
			-- no need for flashlight ever, permanent heatvision instead
			self:attach( "buff_vigilant_stalker" )
		end
		]=],
	},
	attributes = {
		speed			 = 1.1,
		accuracy		 = 10,
		experience_value = 32,
		health			 = 65, -- >60, Hunter (not Cleaner) weapons should help kill this mofo
	},
	data = {
		ai = {
			hunt			   = "vigilant_hunt",
			-- make sure dashing players are still tagged beyond good range
			fire_ch_base	   = 50,
			-- but penalize shooting targets in cover from afar
			long_miss_penalty  = -20,
			-- presume damage chunk within this range is decent
			range			   = 4,
			-- track player through walls
			heat_vision		   = {
				-- lower value didn't seem to do much
				range		   = 7,
				-- do shoot *if* already aware of this particular target
				attack_through = true,
			},
			-- shoot in melee range until weapon is emptied, *only* then switch
			-- to melee. Requires melee > 0
			shoot_unless_empty = true,
		},
	},
}

-- Again, this amp is not meant to be equippable by player.
-- Skirmishers don't aim, whereas for marksmen I took pains to implement Aim support
register_blueprint "vigilant_amp_skirmish"
{
	flags = { EF_NOPICKUP },
	text = { -- must have text.name or will crush generator.roll_perks (internally name is prepended by AV tier)
		name = "pistol AMP",
		desc = "Advanced utility device for use with pistols, SMGs and revolvers. Properties vary.",
	},
	data = {
		perk = {
			type	 = "perk_c",
			subtype	 = "amp",
			subtype2 = "pistol",
			mod		= { perk_ab_pistol_focus = 0 }
		},
		ai_buff = true,
	},
	callbacks = {
		on_create = [=[
			function(self,_,tier)
				generator.roll_perks( self, tier )
			end
		]=],
	},
}

register_blueprint "buff_skirmisher_dodge"
{
	flags = { EF_NOPICKUP },
	text = {
		name = "Dodge",
		desc = "increases evasion",
	},
	ui_buff = {
		color     = LIGHTBLUE,
		attribute = "evasion",
		priority  = 100,
	},
	attributes = {
		evasion = 0,
	},
	callbacks = {
		on_action = [[
			function ( self, entity, time_passed, last )
				-- remove dodge perks from MoreExaltedPerks mod that may be added to skirmisher
				-- on I! difficulty. This way avoid double dodge increase
				world:destroy( entity:child( "mod_exalted_soldier_dodge" ) )
				world:destroy( entity:child( "mod_exalted_dodge_buff" ) )
				if time_passed > 0 then
					local evasion = self.attributes.evasion
					if evasion > 0 then
						if last >= COMMAND_MOVE and last <= COMMAND_MOVE_F then
							self.attributes.evasion = math.floor( evasion / 2 )
						else
							self.attributes.evasion = 0
						end
					end
				end
			end
		]],
		on_move = [[
			function ( self, entity )
				self.attributes.evasion = math.min( self.attributes.evasion + 50, 100 )
			end
		]],
	},
}

-- Skirmisher is adrenal-overloaded unarmored SMG troop that rushes its targets, and has some health buffer
register_blueprint "v_skirmisher0"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ keywords = { "beyond",  "former", "former3", "civilian" }, weight = 30, dmax = 18, },
		{ keywords = { "callisto",	"former", "former3", "civilian" }, weight = 30, dmin = 14, dmax = 18, },
		{ 2, keywords = { "callisto", "beyond", "former", "former3", "civilian" }, weight = 65, dmin = 19, dmax = 21, },
		{ { "v_skirmisher0", "v_skirmisher0", "v_marksman0", } ,
			keywords = { "callisto", "europa", "beyond", "pack", "former", "former3", "civilian" }, weight = 60, dmin = 22, },
		{ { { "v_skirmisher0", tier = 2 }, "v_marksman0", "v_skirmisher0", } ,
			keywords = { "callisto", "europa", "io", "beyond", "pack", "former", "former3", "civilian" }, weight = 40, dmin = 28, },
		{ { { "v_skirmisher0", tier = 3 }, "v_marksman0", "v_marksman0", } ,
			keywords = { "callisto", "europa", "io", "beyond", "pack", "former", "former3", "civilian" }, weight = 20, dmin = 30, },
	},
	ascii	  = {
		glyph	  = "h",
		color	  = LIGHTGREEN,
	},
	text  = {
		name  = "hellish skirmisher",
		namep = "hellish skirmishers",
	},
	callbacks = {
		on_create = [=[
		function( self, level, tier )
			if tier > 1 then
				make_weapon_entry( self, { "adv_esmg", "ammo_cells", 15, tier = tier - 1 } )
			else
				make_weapon( self, level, {
					{ "esmg", "ammo_cells", 20,	 weight = 9, min_depth = 21, },
					{ "asmg", "ammo_762",	16,	 weight = 5, min_depth = 7,  },
					{ "smg",  "ammo_9mm",	20,	 weight = 1, max_depth = 6 , },
				})
			end
			if level.level_info.low_light then
				self:attach( "npc_flashlight" )
			end
			self:attach( "buff_skirmisher_dodge" )
			vigil_tk.equip_amp_tier( self, level, "vigilant_amp_skirmish", tier )
		end
		]=],
	},
	attributes = {
		speed			 = 1.2,
		experience_value = 25,
		accuracy		 = 10,
		health			 = 60, -- <=60 is still Cleaner, not Hunter
	},
	data = {
		ai = {
			hunt			   = "vigilant_hunt",
			fire_ch_base	   = 35,
			cover			   = false,
			-- heightened fire chance when have optimal range
			-- but still need to get close sometimes (when player is in cover), so
			-- don't set too high
			fire_ch_mod		   = 14,
			-- to simulate good tactics in close quarters, use close-ranged heat
			-- vision... though nah, JH stock AI ain't cheaters so modded shouldn't be either.
			-- I gave him dodge to replace that.
			--heat_vision		   = {
			--	range		   = 3,
			--	-- not intended to be real heat vision
			--	attack_through = false,
			--},
			-- smgs are deadlier then punching
			shoot_unless_empty = true,
		},
	},
}

