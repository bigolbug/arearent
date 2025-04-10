--[[
TO DO
figure out how to get settings from the minetest config section. 


]]--

area_rent.startTime = os.clock()
area_rent.metadata = core.get_mod_storage()
area_rent.xp_hit = 4 -- This number represents the damage on a punch. Higher levels of damage indicate a powerful player. 
area_rent.Queable_Area_Limit = 5

--if center is not set log that center should be set and disable rental
if not area_rent.metadata:contains("center") then
    --Log entry...
    area_rent.metadata:set_int("setup",0) -- TODO add entry for all commands that tells us to set center
else
    local meta_center_pos = area_rent.metadata:get_string("center")
    area_rent.origin = core.deserialize(meta_center_pos)
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
    volume = 5000
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
        xp_redo.add_xp(hittername,-1)
    end
    core.chat_send_all(damage)
    core.chat_send_all(time_from_last_punch)
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