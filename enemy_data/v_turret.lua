nova.require "data/lua/core/common"
nova.require "data/lua/core/aitk"
nova.require "data/lua/jh/data/gtk"
nova.require "data/lua/jh/data/common"
nova.require "data/lua/jh/data/entities/turret"
nova.require "data/lua/jh/data/items/ammo"

hook_add_v_turret = {}

function hook_add_v_turret.in_terminals()
	-- credit: Deemzul, string substitution on callbacks in blueprints
	-- (the discussion of best way for terminals to acknowledge new turrets
	-- took place on Discord. Note: the best way as in low maintenance when
	-- new versions of the game get released and terminal code gets modified,
	-- not as "most abstract approach" for detecting turrets)
	local bp_activate = {"terminal_disable_turrets", "terminal_hack_turrets", "terminal_security"}
	for _, bp in ipairs( bp_activate ) do
		local s = blueprints[bp].callbacks.on_activate
		-- in terminal_security.on_activate, only the first occurrence is related to turrets, the other
		-- to drones
		local n, nb	 = string.find( s, "level:enemies{", 1, true )
		if nb then
			s = string.sub( s, 1, nb ).."\"v_rail_turret\","..string.sub( s, nb+1 )
			blueprints[bp].callbacks.on_activate = s
		else
			nova.warning("hook_add_v_turret: target string absent in "..bp.." !")
		end
	end
end

function hook_add_v_turret.in_traits()
	-- reusing Deemzul's recipe here as well.
	local s = blueprints["trait_remote_hack"].callbacks.on_post_command
	local n, nb = string.find( s, "id == \"turret\"", 1, true )
	if nb then
		s = string.sub( s, 1, nb ).." or id == \"v_rail_turret\""..string.sub( s, nb+1 )
		blueprints["trait_remote_hack"].callbacks.on_post_command = s
	else
		nova.warning("hook_add_v_turret: target string absent in trait_remote_hack !")
	end
end

function hook_add_v_turret.run(self)
	if self.already then
		nova.warning("v_turret: attempt to run hook a second time")
		return
	end
	self.already = true
	-- credit: Deemzul for the whole approach with modifying callbacks in blueprints
	self.in_terminals()
	self.in_traits()
end

hook_add_v_turret.run(hook_add_v_turret)

-- weapon for rail turret. Rather disappointed that dodge can dismiss rail shot
register_blueprint "vigilant_turret_rail"
{
	clip = {
		count = 1,
		reload_sound = "reload",
	},
	attributes = {
		reload_time  = 2.0,
		damage		 = 36,
		clip_size	 = 1,
		min_distance = 2,
		opt_distance = 7,
		max_distance = 14,
		crit_chance  = 25,
		crit_damage  = 50,
	},
	weapon = {
		group       = "semi",
		type		= "rail",
		damage_type = "pierce",
		natural     = true,
		fire_sound  = "vturret_rail_shot",
	},
	noise = {
		use = 12,
		hit = 16,
	},
}

register_blueprint "v_turret_charge"
{
	flags = { EF_NOPICKUP },
	text = {
		name = "Tracking",
		desc = "accuracy increased by the given value"
	},
	ui_buff = {
		color = LIGHTRED,
		attribute = "accuracy",
		priority  = 110,
	},
	attributes = {
		accuracy = 0,
	},
	callbacks = {
		on_die = [=[
			function( self )
				world:mark_destroy( self )
			end
		]=],
	},
}

function aitk.vigilant_turret_ready( self )
	local level = world:get_level()
	self.data.ai.target_coord = nil
	if not level:is_alive( self.target.entity ) then
		self.target.entity = aitk.pick_target( self )
	end
	if not level:can_see_entity( self, self.target.entity, self.data.ai.vision or 8 ) then
		self.target.entity = nil
	end
	if self.target.entity then
		self.data.ai.target_coord = world:get_position( self.target.entity )
		level:rotate_towards( self, self.target.entity )
		aitk.do_attack( self, self.data.ai.target_coord )
		return "turret_attack"
	else -- reset accuracy to 0
		self:child("v_turret_charge").attributes.accuracy = 0
		world:command( COMMAND_WAIT, self )
		return "turret_idle"
	end
end

function aitk.vigilant_turret_attack( self )
	local level = world:get_level()
	if aitk.do_reload( self ) then
		if self.target.entity then
			level:rotate_towards( self, self.target.entity )
		end
		self:child("v_turret_charge").attributes.accuracy = 100
		return "turret_ready"
	end
	if not level:is_alive( self.target.entity ) then
		self.target.entity = aitk.pick_target( self )
		if not level:is_alive( self.target.entity ) then
			self:child("v_turret_charge").attributes.accuracy = 0
			world:command( COMMAND_WAIT, self )
			return "turret_idle"
		end
	end
	if level:can_see_entity( self, self.target.entity, self.data.ai.vision or 8 ) then
		self.data.ai.target_coord = world:get_position( self.target.entity )
		level:rotate_towards( self, self.target.entity )
	else
		self:child("v_turret_charge").attributes.accuracy = 0
	end
	aitk.do_attack( self, self.data.ai.target_coord )
	return "turret_attack"
end

function aitk.vigilant_turret_idle( self )
	local level = world:get_level()
	self.data.ai.target_coord = nil
	if not level:is_alive( self.target.entity ) then
		self.target.entity = aitk.pick_target( self )
	end
	if not level:can_see_entity( self, self.target.entity, self.data.ai.vision or 8 ) then
		self.target.entity = nil
		self:child("v_turret_charge").attributes.accuracy = 0
		if math.random(50) == 1 then
			world:play_sound( "idle", self )
		end
		world:command( COMMAND_WAIT, self )
		return "turret_idle"
	end
	-- prepared shot. One which no doubt must have bonus accuracy
	self:child("v_turret_charge").attributes.accuracy = 100
	world:play_sound( "turret_target", self )
	level:rotate_towards( self, self.target.entity )
	world:command( COMMAND_WAIT, self )
	level:rotate_towards( self, self.target.entity )
	self.data.ai.target_coord = world:get_position( self.target.entity )
	return "turret_attack"
end

-- exalted faction rail turret, for balance reasons you can still disable it from terminal
register_blueprint "v_rail_turret"
{
	blueprint = "turret_common",
	lists = {
		group = "turret",
		-- currently I prevent it from spawning in Io Black Site and normal Io levels
		-- in base game, but this also causes it to appear late in Endless Beyond-themed levels
		{ keywords = { "beyond", "io", "callisto", "europa", "turret", "civilian", "bot" }, weight = 100, dmin = 27, },
		-- because callisto doesn't have a rocket turret, I leave this entry to effectively sum weights with other
		-- entries in effect
		{ keywords = { "callisto", "turret", "civilian", "bot" }, weight = 50, dmin = 15, },
		{ keywords = { "callisto", "europa", "turret", "civilian", "bot" }, weight = 75, dmin = 22, dmax = 26, },
		-- { keywords = { "europa", "turret", "civilian", "bot" }, weight = 500, dmin = 13, }, -- used for testing
	},
	text = {
		name	  = "rail turret",
		namep	  = "rail turrets",
		entry	  = "Rail Turret",
	},
	ascii	  = {
		glyph	  = "T",
		color	  = LIGHTBLUE,
	},
	callbacks = {
		on_create = [=[
		function( self )
			self:attach( "vigilant_turret_rail" )
			self:attach( "v_turret_charge" )
			self:attach( "ammo_cells", { stack = { amount = 3 + math.random(5) } } )
			local hack	  = self:attach( "terminal_bot_hack" )
			hack.attributes.tool_cost = 4
			local disable = self:attach( "terminal_bot_disable" )
			disable.attributes.tool_cost = 2
			self:attach( "terminal_return" )
		end
		]=],
	},
	attributes = {
		experience_value = 35,
		health			 = 70,
		-- turret_common has accuracy penalty, so this has to be explicitly set to 0, if not
		-- higher, since doesn't make sense for a freaking rail turret to have penalty to accuracy.
		accuracy		 = 0,
	},
	data = {
		ai = {
			group         = "exalted",
			state         = "vigilant_turret_idle",
			idle          = "vigilant_turret_idle",
			find          = "vigilant_turret_idle",
			hunt          = "vigilant_turret_attack",
			turret_idle   = "vigilant_turret_idle",
			turret_attack = "vigilant_turret_attack",
			turret_ready  = "vigilant_turret_ready",
			vision        = 10,
		},
	},
}
