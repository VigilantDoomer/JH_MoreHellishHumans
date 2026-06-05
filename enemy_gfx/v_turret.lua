nova.require "data/lua/gfx/common"
nova.require "data/lua/jh/gfx/common"

register_gfx_blueprint "v_turret_charge" {}

register_gfx_blueprint "fx_on_fire_vigilant_turret_beam"
{
	blueprint = "fx_energy_muzzle_flash",
	lifetime = {
		duration = 0.25,
	},
	light = {
		color		= vec4(0.15,0.41,0.9,1.0),
		range		= 4,
	},
	fade = {
		fade_in	 = 0.2,
		fade_out = 1.0,
		destroy	 = true,
	},
	camera_shake = {
		power		= 0.15,
		duration	= 0.1,
	},
}

register_gfx_blueprint "fx_on_shot_vigilant_turret_beam"
{
	fx = {
		tag	   = "RigHub001",
		attach = true,
	},
	lifetime = {
		duration = 2.8,
	},
	sprite = {
		material = "enemy_gfx/vigilant_beam",
		size	 = vec2( 0.6, 0.6 ),
		beam	 = "segmented",
	},
	target = {
		offset	 = vec3( 0.0, 1.0, 0.0 ),
	},
	fade = {
		fade_in	 = 0.1,
		fade_out = 0.2,
		easing	 = EASING_SINE,
	},
	point_generator = {
		type		  = "helix",
		extents		  = vec3(0.7,1.5,3.0),
		inner_extents = vec3(0.1,0.0,0.0),
	},
	particle = {
		material	   = "data/texture/particles/shapes_01/blick_01",
		group_id	   = "pgroup_fx",
		orientation	   = PS_ORIENTED,
	},
	particle_emitter = {
		rate	 = 512,
		size	 = 0.1,
		velocity = -0.8,
		color	 = vec4(0.35,0.85,0.85,1.0),
		lifetime = 0.25,
		duration = 0.14,
	},
	particle_fade = {
		fade_out = 0.5,
	},
	particle_size_hack = true,
}

register_gfx_blueprint "fx_on_damage_vigilant_turret_beam"
{
	fx = {
		attach	  = true,
		at_target = true,
	},
	lifetime = {
		duration = 2.0,
	},
	fade = {
		fade_out = 1.8,
	},
	target = {
		track	  = true,
		offset	  = vec3( 0.0, 1.0, 0.0 ),
	},
	physics_explosion = {
		radius = 0.5,
	},
	physics_hit = {
		mass = 5.0,
		speed = 40.0,
		from_source = true,
	},
	light = {
		color		= vec4(0.1,1.0,1.0,1.0),
		range		= 2,
	},
	camera_shake = {
		power		= 0.495,
		duration	= 0.35,
	},
	point_generator = {
		type	 = "cylinder",
		position  = vec3(0.0,0.7,0.0),
		extents	  = 0.05,
	},
	"ps_explosion_crater",
}

register_gfx_blueprint "vigilant_turret_rail"
{
	weapon_fx = {
		on_fire	   = "fx_on_fire_vigilant_turret_beam",
		on_shot	   = "fx_on_shot_vigilant_turret_beam",
		on_damage  = "fx_on_damage_vigilant_turret_beam",
		velocity   = 100.0,
	},
	attach = "turret_body_mount_stand_01",
	render = {
		mesh	 = "data/model/turret_01.nmd:turret_rocket_launcher_01_R",
		material = "data/texture/turret_01/A/turret_rocket_launcher_01_R",
	},
	{
		render = {
			mesh	 = "data/model/turret_01.nmd:turret_rocket_launcher_01_L",
			material = "data/texture/turret_01/A/turret_rocket_launcher_01_L",
		},
	},
	equip = {},
}

register_gfx_blueprint "v_rail_turret"
{
	{
		scene = {},
		{
			attach = "turret_body_mount_stand_01",
			render = {
				mesh	 = "data/model/turret_01.nmd:turret_body_01",
				material = "data/texture/turret_01/A/turret_body_01",
			},
		},
		{
			attach = "turret_body_mount_stand_01",
			render = {
				mesh	 = "data/model/turret_01.nmd:turret_back_cover_01",
				material = "data/texture/turret_01/A/turret_body_01",
			},
		},
	},
	light = {
		position	= vec3(0,0.1,0),
		color		= vec4(0.4,1.48,1.5,1.0),
		range		= 1.15,
	},
}
