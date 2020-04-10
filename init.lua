--- HIDDEN GADGETS ---
minetest.register_node("xgadgets:stone", {
	description = "Phantom Stone",
	drawtype = "nodebox",
	inventory_image = "xgadgets_stone_inv.png", --- Differnt invetory image so you can tell between stone
	pointable = true,
	walkable = false, 
	buildable_to = false,
	drop = "default:mese_crystal 8",
	diggable = true, --- Not air so you can break it
	post_effect_color = {a=75, r=100, g=0, b=0}, --- Red Color
	tile_images = {"xgadgets_stone.png"},
	groups = {cracky=2},
})
minetest.register_craft({
	output = "xgadgets:stone",
	recipe = {
		{"", "default:stone", ""},
		{"default:stone", "default:mese_block", "default:stone"},
		{"", "default:stone", ""},
	}
})
-- Hidden Trapdoor
if minetest.get_modpath("doors") then
xgadgets = {}
xgadgets.registered_trapdoors = {}
function xgadgets.trapdoor_toggle(pos, node, clicker)
	node = node or minetest.get_node(pos)

	if clicker and not default.can_interact_with_node(clicker, pos) then
		return false
	end

	local def = minetest.registered_nodes[node.name]

	if string.sub(node.name, -5) == "_open" then
		minetest.sound_play(def.sound_close,
			{pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = string.sub(node.name, 1,
			string.len(node.name) - 5), param1 = node.param1, param2 = node.param2})
	else
		minetest.sound_play(def.sound_open,
			{pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = node.name .. "_open",
			param1 = node.param1, param2 = node.param2})
	end
end

function xgadgets.register_trapdoor(name, def)
	if not name:find(":") then
		name = "xgadgets:" .. name
	end

	local name_closed = name
	local name_opened = name.."_open"

	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		xgadgets.trapdoor_toggle(pos, node, clicker)
		return itemstack
	end

	-- Common trapdoor configuration
	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.is_ground_content = false

	if not def.sounds then
		def.sounds = default.node_sound_wood_defaults()
	end

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end

	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.tiles = {def.tile_front,
			def.tile_front .. '^[transformFY',
			def.tile_side, def.tile_side,
			def.tile_side, def.tile_side}

	def_opened.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.tiles = {def.tile_side, def.tile_side,
			def.tile_side .. '^[transform3',
			def.tile_side .. '^[transform1',
			def.tile_front .. '^[transform46',
			def.tile_front .. '^[transform6'}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	xgadgets.registered_trapdoors[name_opened] = true
	xgadgets.registered_trapdoors[name_closed] = true
end

xgadgets.register_trapdoor("xgadgets:trapdoor", {
	description = "Hidden Trapdoor",
	inventory_image = "xgadgets_trapdoor.png",
	wield_image = "xgadgets_trapdoor.png",
	tile_front = "default_grass.png",
	tile_side = "default_grass.png",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, door = 1},
})

minetest.register_craft({
	output = "xgadgets:trapdoor",
	recipe = {
		{"default:grass_1", "default:grass_1", "default:grass_1"},
		{"default:grass_1", "doors:trapdoor", "default:grass_1"},
		{"default:grass_1", "default:grass_1", "default:grass_1"},
	}
})
end

--- THROWABLE GADGETS ---
-- Function to make bottles that are throwable and place blocks
function xgadgets_register_throwable(name, descr, def)
    minetest.register_craftitem("xgadgets:"..name.."_bottle", {
        description = descr,
		physical = true,
		stack_max = 1,
        inventory_image = "xgadgets_" ..name.."_bottle.png",
        on_use = function(itemstack, placer, pointed_thing)
            --weapons_shot(itemstack, placer, pointed_thing, def.velocity, name)
            local dir = placer:get_look_dir();
            local playerpos = placer:getpos();
			posthrow = playerpos
            local obj = minetest.env:add_entity({x=playerpos.x+0+dir.x,y=playerpos.y+2+dir.y,z=playerpos.z+0+dir.z}, "xgadgets:"..name.."_bottle_explosion")
            local vec = {x=dir.x * 7, y=dir.y * 1, z=dir.z * 7}
            local acc = {x=0, y=-9.8, z=0}
            obj:setvelocity(vec)
            obj:setacceleration(acc)
            itemstack:take_item()
            return itemstack
        end,
    })

    minetest.register_entity("xgadgets:"..name.."_bottle_explosion",{
        textures = {"xgadgets_" ..name.."_bottle.png"},
		collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
        on_step = function(self, dtime)
            local pos = self.object:getpos()
            local node = minetest.get_node(pos)
			local n = node.name
            if n ~= "air" then
                def.hit_node(self, pos)
                self.object:remove()
            end
        end,
    })
end
-- Flaming Bottle
xgadgets_register_throwable("fire", "Flaming Bottle", {
    hit_node = function(self,pos)
        for dx = 0,1 do
            for dy = 0,1 do
                for dz = 0,1 do
                    local pos1 = {x = pos.x+dx, y=pos.y+dy, z=pos.z+dz}
                    if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                        minetest.set_node(pos1, {name="fire:basic_flame"})
                    end
                end
            end
        end
    end,
})
-- Net Bottle
xgadgets_register_throwable("net", "Net Bottle", {
    hit_node = function(self,pos)
        for dx = 0,1 do
            for dy = 0,1 do
                for dz = 0,1 do
                    local pos1 = {x = pos.x+dx, y=pos.y+dy, z=pos.z+dz}
                    if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                        minetest.set_node(pos1, {name="xgadgets:net_trap"})
                    end
                end
            end
        end
    end,
})
-- Explosive Bottle
local bottle_boom = {
	name = "xgadgets:bottle_explosion",
	radius = 2,
	tiles = {
		side = "xgadgets_expolsive_bottle.png",
		top = "xgadgets_expolsive_bottle.png",
		bottom = "xgadgets_expolsive_bottle.png",
		burning = "xgadgets_expolsive_bottle.png"
	},
}

minetest.register_craftitem("xgadgets:expolsive_bottle", {
	stack_max= 1,
	wield_scale = {x=1.1,y=1.1,z=1.05},
	description = "Explosive Bottle",
	range = 0,
	inventory_image = "xgadgets_expolsive_bottle.png",
})
minetest.register_craftitem("xgadgets:expolsive_bottle_ready", {
	stack_max= 1,
	wield_scale = {x=1.1,y=1.1,z=1.05},
	description = "Explosive Bottle Burning",
	range = 0,
	inventory_image = "xgadgets_expolsive_bottle_ready.png",
	groups = {not_in_creative_inventory = 1},
	on_use = function(itemstack, user, pointed_thing)
		local pos = user:getpos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 1.6
			local obj = minetest.add_entity(pos, "xgadgets:bottle")
			if obj then
				obj:setvelocity({x=dir.x * 7, y=dir.y * 1, z=dir.z * 7})
				obj:setacceleration({x=dir.x * -1, y=-6, z=dir.z * -1})
				obj:setyaw(yaw + math.pi)
				local ent = obj:get_luaentity()
				if ent then
					ent.player = ent.player or user
			itemstack = ""
				end
			end
		end
		return itemstack
	end,
})

	local timer = 0
minetest.register_globalstep(function(dtime, player, pos)
	timer = timer + dtime;
	if timer >= 0.001 then
	for _, player in pairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		local controls = player:get_player_control()
		if player:get_wielded_item():get_name() == "xgadgets:expolsive_bottle" then
		if controls.RMB then
		player:set_wielded_item("xgadgets:expolsive_bottle_ready")
		timer = 0
				minetest.sound_play("tnt_ignite", {player})
		local dir = player:get_look_dir()
		local yaw = player:get_look_yaw()
		if pos and dir and yaw then
			pos.y = pos.y + 0.3
			end

end
	end

	if timer >= 1.5 and
		 player:get_wielded_item():get_name() == "xgadgets:expolsive_bottle_ready" then
		player:set_wielded_item("")
		timer = 0
		tnt.boom(pos, bottle_boom)

		end
			end
				end
				end)

local xgadgets_bottle = {
	physical = false,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.5, y=0.5},
	textures = {"xgadgets_expolsive_bottle_ready.png"},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}
xgadgets_bottle.on_step = function(self, dtime, pos)
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)
	if self.lastpos.x ~= nil then
	if minetest.registered_nodes[node.name].walkable then
	local vel = self.object:getvelocity()
	local acc = self.object:getacceleration()
	self.object:setvelocity({x=vel.x*-0.3, y=vel.y*-1, z=vel.z*-0.3})
	self.object:setacceleration({x=acc.x, y=acc.y, z=acc.z})
			end
	end
	self.timer = timer
	if self.timer > 1.5 then
	tnt.boom(pos, bottle_boom)
	self.object:remove()
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}

end
minetest.register_entity("xgadgets:bottle", xgadgets_bottle)
-- Smoke Bottle
minetest.register_entity("xgadgets:smoke", {
	textures = {"xgadgets_smoke_bottle.png"},
	velocity = 0.1,
	damage = 0,
	physical = true,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	on_step = function(self, obj, pos)		
		local remove = minetest.after(5, function() 
		self.object:remove()
		end)
		local pos = self.object:getpos()
			minetest.add_particlespawner(
			32, --amount
			1, --time
			{x=pos.x-3, y=pos.y-3, z=pos.z-3}, --minpos
			{x=pos.x+3, y=pos.y+3, z=pos.z+3}, --maxpos
			{x=-0, y=-0, z=-0}, --minvel
			{x=0, y=0, z=0}, --maxvel
			{x=-0.1,y=0.2,z=-0.1}, --minacc
			{x=0.1,y=0.2,z=0.1}, --maxacc
			6, --minexptime
			12, --maxexptime
			40, --minsize
			50, --maxsize
			false, --collisiondetection
			"xgadgets_smoke.png"
		)
	end,
})
minetest.register_craftitem("xgadgets:smoke_bottle", {
	description = "Smoke Bottle",
	inventory_image = "xgadgets_smoke_bottle.png",
	wield_image = "xgadgets_smoke_bottle.png",
	stack_max = 1,
	is_ground_content = false,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.4, 0.25}
	},
	groups = {vessel=1,dig_immediate=3,attached_node=1},
	sounds = default.node_sound_glass_defaults(),
	inventory_image = "xgadgets_smoke_bottle.png",
	on_use = function(item, placer, pos)
	local dir = placer:get_look_dir();
	local playerpos = placer:getpos();
	local vec = {x=dir.x*6,y=dir.y*3.5,z=dir.z*6}
	local acc = {x=0,y=-9.8,z=0}
	local obj = minetest.env:add_entity({x=playerpos.x+dir.x*2.5,y=playerpos.y+2+dir.y,z=playerpos.z+0+dir.z}, "xgadgets:smoke")
	obj:setvelocity(vec)
	obj:setacceleration(acc)
		item:take_item()
		return item
	end,
})
if minetest.get_modpath("tnt") then
minetest.register_craft({
	output = "xgadgets:fire_bottle",
	recipe = {
		{"tnt:gunpowder", "default:torch", "tnt:gunpowder"},
		{"default:coal_lump", "vessels:glass_bottle", "default:coal_lump"},
		{"tnt:gunpowder", "default:torch", "tnt:gunpowder"},
	}
})
minetest.register_craft({
	output = "xgadgets:net_bottle",
	recipe = {
		{"tnt:gunpowder", "xgadgets:net_trap", "tnt:gunpowder"},
		{"farming:string", "vessels:glass_bottle", "farming:string"},
		{"tnt:gunpowder", "xgadgets:net_trap", "tnt:gunpowder"},
	}
})
minetest.register_craft({
	output = "xgadgets:expolsive_bottle",
	recipe = {
		{"tnt:gunpowder", "default:mese_crystal", "tnt:gunpowder"},
		{"default:coal_lump", "vessels:glass_bottle", "default:coal_lump"},
		{"tnt:gunpowder", "default:mese_crystal", "tnt:gunpowder"},
	}
})
minetest.register_craft({
	output = "xgadgets:smoke_bottle",
	recipe = {
		{"tnt:gunpowder", "default:coal_lump", "tnt:gunpowder"},
		{"default:coal_lump", "vessels:glass_bottle", "default:coal_lump"},
		{"tnt:gunpowder", "default:coal_lump", "tnt:gunpowder"},
	}
})
end
--- TRAP GADGETS ---
if minetest.get_modpath("farming") then
minetest.register_node("xgadgets:net_trap", {
	description = "Net Trap",
	paramtype = "light",
	drawtype = "plantlike",
	tiles = {"xgadgets_net_trap.png"},
	inventory_image = "xgadgets_net_trap.png",
	liquid_viscosity = 9,
	liquidtype = "source",
	liquid_alternative_flowing = "xgadgets:net_trap",
	liquid_alternative_source = "xgadgets:net_trap",
	liquid_renewable = false,
	liquid_range = 0,
	walkable = false,
    sunlight_propagates = true,
	drop = "farming:string 3",
	selection_box = {type = "regular"},
	groups = {oddly_breakable_by_hand=1, snappy=2, liquid=3, flammable=3},
	sounds = default.node_sound_leaves_defaults()
})
minetest.register_craft({
	output = "xgadgets:net_trap",
	recipe = {
		{"farming:string", "", "farming:string"},
		{"", "farming:string", ""},
		{"farming:string", "", "farming:string"},
	}
})
end