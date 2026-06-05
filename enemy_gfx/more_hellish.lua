nova.require "data/lua/gfx/common"

register_gfx_blueprint "vigilant_kevlar" {}
register_gfx_blueprint "vigilant_plate" {}
register_gfx_blueprint "vigilant_amp_pistol" {}
register_gfx_blueprint "vigilant_amp_skirmish" {}

register_gfx_blueprint "v_stalker_beret"
{
	blueprint = "pf_security_beret",
	light = {
		position	= vec3(0,0.1,0),
		color		= vec4(1.8,0.2,0.3,1.0),
		range		= 1.1,
	},
}

register_gfx_blueprint "v_marksman0"
{
	blueprint = "security_base",
	style = {
		materials = {
			security_shoulders	= "data/texture/security/C/security_shoulders",
			security_helmet		= "data/texture/security/C/security_helmet",
			security_body_A		= "data/texture/security/C/security_body_A",
			security_body_B		= "data/texture/security/C/security_body_B",
			security_body_C		= "data/texture/security/C/security_body_C",
		},
	},
	"pf_security_shoulders",
	"pf_security_helmet",
	"pf_security_body_ABC",
}

register_gfx_blueprint "v_skirmisher0"
{
	blueprint = "security_base",
	style = {
		materials = {
			security_shoulders	= "data/texture/security/C/security_shoulders",
			security_purse		= "data/texture/security/C/security_purse",
			security_body_A		= "data/texture/security/C/security_body_A",
			security_body_B		= "data/texture/security/C/security_body_B",
			security_body_C		= "data/texture/security/C/security_body_C",
		},
	},
	"pf_security_hair",
	"pf_security_shoulders",
	{
		chance	  = 0.6,
		blueprint = "pf_security_purse",
	},
	"pf_security_body_ABC",
}

register_gfx_blueprint "v_sergeant0"
{
	blueprint = "security_base",
	style = {
		materials = {
			security_shoulders	= "data/texture/security/C/security_shoulders",
			security_purse		= "data/texture/security/C/security_purse",
			security_beret		= "data/texture/security/C/security_beret_A",
			security_body_A		= "data/texture/security/C/security_body_A",
			security_body_B		= "data/texture/security/C/security_body_B",
			security_body_C		= "data/texture/security/C/security_body_C",
		},
	},
	"v_stalker_beret",
	"pf_security_shoulders",
	"pf_security_purse",
	"pf_security_body_ABC",
}
