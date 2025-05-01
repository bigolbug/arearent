--[[
TO DO
figure out how to get settings from the minetest config section. 


]]--
area_rent.enabled = true
area_rent.debuglevel = "info" -- options "info" "none", "error", "warning", "action", or "verbose"
area_rent.startTime = os.clock()
area_rent.metadata = core.get_mod_storage()
area_rent.xp_hit = 4 -- This number represents the damage on a punch. Higher levels of damage indicate a powerful player. 
area_rent.cueable_Area_Limit = 5
area_rent.qualifying_term = 30
area_rent.cue_expiration = 60
area_rent.day_interval = core.settings:get("time_speed") + 0
area_rent.scan_interval = area_rent.day_interval / 10
area_rent.border_experation = 30

if area_rent.scan_interval == 0 then
    area_rent.scan_interval = 5 
end
area_rent.start_day = core.get_day_count()

if area_rent.metadata:get_string("border_list") then
    area_rent.metadata:set_string("border_list",nil)
end

--if center is not set log that center should be set and disable rental
if not area_rent.metadata:contains("center") then
    --Log entry...
    area_rent.debug("Area rent center not set")
    area_rent.metadata:set_int("setup",0) -- TODO add entry for all commands that tells us to set center    
end

--Initialize Renter List
if not area_rent.metadata:contains("renters") then
    --Add Log entry??
    local renters = {}
    core.log("error","Renters Table not set, creating entry")
    area_rent.metadata:set_string("renters",core.serialize(renters)) -- TODO add entry for all commands that tells us to set center
end


--Limit and inflation
-- We need to keep track of how many properties or the amount of the map
-- These settings should be configured in the settings section of minetest 
area_rent.limit = {
    hrz_ratio = .3,-- shortest side / longest side
    vrt_ratio = 7, -- height / shortest side
    h_min = 20, -- Min height 
    w_max = 20, -- Max Width
    w_min = 3,
    properties = 10,
    volume = 5000,
    viewable_dist = 50
}
area_rent.price = {
    rate = function (x)
        -- x is the distance from the oragin accurate up to three siginifigant digits. 
        local rate = -.000004*x + .008
        if rate < .001 then
            rate = .001
        end
        return string.format("%.3f",rate)
    end
}

-- This next section is kind of random
-- I wanted to limit the amount of griefing that was happening. 
core.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage) 
    local playername = player:get_player_name()
    local hittername = hitter:get_player_name()
    if damage > area_rent.xp_hit then
        arae_rent.updateXP(hittername,-10)
    end
    --core.chat_send_all(damage)
    --core.chat_send_all(time_from_last_punch)
end)

--[[
area_rent.limit.price = {}
area_rent.limit.price.inflation = .15  -- Inflate the price for more then count limit
area_rent.limit.price.base = 100
area_rent.limit.areas = 2
area_rent.limit.inflation = .15
area_rent.price.center = 5
area_rent.price.per_node_radius = 2000
area_rent.price.outer = .0125
area_rent.price.per.area = 2

]]--

core.register_entity("area_rent:border_NX", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1, y=1},
		textures = {"area_rent_transparent.png","area_rent_transparent.png",
            "area_rent_transparent.png", "area_rent_fullframe.png",
            "area_rent_transparent.png","area_rent_transparent.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})
core.register_entity("area_rent:border_PX", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1, y=1},
        textures = {"area_rent_transparent.png",-- +Y
        "area_rent_transparent.png",-- -Y
        "area_rent_fullframe.png",-- +X
        "area_rent_transparent.png",-- -X
        "area_rent_transparent.png",-- +Z
        "area_rent_transparent.png"},-- -Z
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})
core.register_entity("area_rent:border_PZ", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1, y=1},
		textures = {"area_rent_transparent.png",-- +Y
        "area_rent_transparent.png",-- -Y
        "area_rent_transparent.png",-- +X
        "area_rent_transparent.png",-- -X
        "area_rent_fullframe.png",-- +Z
        "area_rent_transparent.png"},-- -Z
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})
core.register_entity("area_rent:border_NZ", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1, y=1},
		textures = {"area_rent_transparent.png",-- +Y
        "area_rent_transparent.png",-- -Y
        "area_rent_transparent.png",-- +X
        "area_rent_transparent.png",-- -X
        "area_rent_transparent.png",-- +Z
        "area_rent_fullframe.png"},-- -Z
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		hp_max = 1,
		armor_groups = {fleshy=100},
		static_save = false,
	},
})