mcl_moreblocks = {}


-- add nodename as a block supported by the circular saw
mcl_moreblocks.add_block = function(nodename)
	local i = string.find(nodename, ":")
	local mod  = string.sub(nodename, 1, i-1)
	local name = string.sub(nodename, i+1)
	if(minetest.registered_nodes[nodename]) then
		local ndef = table.copy(minetest.registered_nodes[nodename])
		ndef.sunlight_propagates = true

		-- Use the primary tile for all sides of cut glasslike nodes and disregard paramtype2.
		if #ndef.tiles > 1 and ndef.drawtype and ndef.drawtype:find("glass") then
			ndef.tiles = {ndef.tiles[1]}
			ndef.paramtype2 = nil
			ndef.use_texture_alpha = "clip" -- only needed for stairs API
		end

		-- the shapes shall not be falling nodes (especially not the concrete powder)
		if(ndef.groups and ndef.groups.falling_node) then
			ndef.groups.falling_node = nil
		end

		stairsplus:register_all(mod, name, nodename, ndef)
	end
end


-- plug into the slab registration process of MCL stairs so that we can add
-- them to moreblocks as well
local old_mcl_stairs_register_slab = mcl_stairs.register_slab
mcl_stairs.register_slab = function(subname, ...)
	-- call the old function
	old_mcl_stairs_register_slab(subname, ...)
	-- MineClone2 and MineClonia pass *diffrent* parameters here!
	local def = select(1, ...)
	if(type(def) == "table" and (def.recipeitem or def.baseitem)) then
		mcl_moreblocks.add_block(def.recipeitem or def.baseitem)
	elseif(type(def) == "string") then
		mcl_moreblocks.add_block(def)
	end
end


mcl_moreblocks.add_nodes = function()
	-- these nodes are already added by mcl_stairs/register.lua - we can't catch
	-- them with the function above and have to add them manually
	local other_nodes = {
		"mcl_core:wood",
		"mcl_core:junglewood",
		"mcl_core:acaciawood",
		"mcl_core:sprucewood",
		"mcl_core:birchwood",
		"mcl_core:darkwood",
		"mcl_core:stone",
		"mcl_core:stone_smooth",
		"mcl_core:andesite",
		"mcl_core:granite",
		"mcl_core:diorite",
		"mcl_core:cobble",
		"mcl_core:mossycobble",
		"mcl_core:brick_block",
		"mcl_core:sandstone",
		"mcl_core:sandstonesmooth2",
		"mcl_core:redsandstone",
		"mcl_core:redsandstonesmooth2",
		"mcl_core:stonebrick",
		"mcl_nether:quartz_block",
		"mcl_nether:quartz_smooth",
		"mcl_nether:nether_brick",
		"mcl_nether:nether_brick",
		"mcl_end:end_bricks",
		"mcl_end:purpur_block",
		"mcl_ocean:prismarine",
		"mcl_ocean:prismarine_brick",
		"mcl_ocean:prismarine_dark",
		"mcl_mud:mud_bricks",
		"mcl_core:andesite_smooth",
		"mcl_core:granite_smooth",
		"mcl_core:diorite_smooth",
		"mcl_core:stonebrickmossy",

		-- not really a stair node in mcl - yet it's worth supporting
		"mcl_core:glass",
	}
	-- in the MineClonia world (but not in MCL2 world), tree trunks cannot be cut; add them:
	if(minetest.registered_nodes["mcl_trees:tree_oak"]) then
		table.insert(other_nodes, "mcl_trees:tree_oak")
		table.insert(other_nodes, "mcl_trees:tree_dark_oak")
		table.insert(other_nodes, "mcl_trees:tree_jungle")
		table.insert(other_nodes, "mcl_trees:tree_spruce")
		table.insert(other_nodes, "mcl_trees:tree_acacia")
		table.insert(other_nodes, "mcl_trees:tree_birch")
		table.insert(other_nodes, "mcl_trees:tree_willow")
		table.insert(other_nodes, "mcl_trees:tree_crimson")
		table.insert(other_nodes, "mcl_trees:tree_warped")
		table.insert(other_nodes, "mcl_trees:tree_bamboo")
		table.insert(other_nodes, "mcl_trees:tree_mangrove")
		table.insert(other_nodes, "mcl_trees:tree_cherry_blossom")
	end

	-- concrete powder has a fine texture and diffrent colors

	-- MineClonia version
	if(mcl_dyes and mcl_dyes.colors) then
		for color,colordef in pairs(mcl_dyes.colors) do
			-- concrete powder (cut shapes will be created as non-falling nodes)
			table.insert(other_nodes, "mcl_colorblocks:concrete_powder_"..color)
			-- wool
			table.insert(other_nodes, "mcl_wool:"..color)
		end

	-- MineClone2 version
	else
		local dyes = {"white", "grey","silver","black","red","yellow","green",
			"cyan","blue","magenta","orange","purple","brown","pink","lime",
			"light_blue"
		}
		for _, color in ipairs(dyes) do
			-- concrete powder (cut shapes will be created as non-falling nodes)
			table.insert(other_nodes, "mcl_colorblocks:concrete_powder_"..color)
			-- wool
			table.insert(other_nodes, "mcl_wool:"..color)
			-- glass does not work that well (only the frame gets colored)
			--table.insert(other_nodes, "mcl_core:glass_"..color)
		end
	end


	-- actually register them with the saw
	for i, name in ipairs(other_nodes) do
		mcl_moreblocks.add_block(name)
	end

end
-- give the mods time enough to load
minetest.after(0, mcl_moreblocks.add_nodes)


-- now adjust the saw as such
-- first: the formspec needs to get a no_prepend[] inserted so that it is usable
--        (the mcl style makes the slots invisible)
new_saw_on_construct = function(pos)
	circular_saw.on_construct(pos)
	local meta = minetest.get_meta(pos)
	local formspec = meta:get_string("formspec")
	local i = string.find(formspec, "]")
	formspec = string.sub(formspec, 0, i).."no_prepend[]"..string.sub(formspec, i+1)

	-- replace "list[current_player;main;1.5,6.25;9,4;]" with something fitting for MCL worlds
	local old_inv_str = "list[current_player;main;1.5,6.25;8,4;]"
	local j = string.find(formspec, old_inv_str)
	formspec = string.sub(formspec, 0, j-1-string.len(old_inv_str))..
		"list[current_player;main;1.5,6.25;9,3;9]"..
		"list[current_player;main;1.5,9.4;9,1;]"
		string.sub(formspec, j+1+string.len(old_inv_str))
	meta:set_string("formspec", formspec)
end
minetest.registered_nodes["moreblocks:circular_saw"].on_construct = new_saw_on_construct

-- then: make the saw diggable (the mcl world isn't compatible with the rest here)
minetest.registered_nodes["moreblocks:circular_saw"].groups = {handy=1,axey=1, tree=1, building_block=1, material_wood=1}


-- add a craft receipe with materials from the MCL world
if minetest.settings:get_bool("moreblocks.circular_saw_crafting") ~= false then -- “If nil or true then”
	minetest.register_craft({
		output = "moreblocks:circular_saw",
		recipe = {
			{ "",  "mcl_core:iron_ingot",  "" },
			{ "group:wood",  "group:wood",  "group:wood"},
			{ "group:wood",  "",  "group:wood"},
		}
	})
end

