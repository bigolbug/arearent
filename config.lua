--[[
TO DO
figure out how to get settings from the minetest config section. 


]]--

area_rent.startTime = os.clock()
area_rent.metadata = minetest.get_mod_storage()

--if center is not set log that center should be set and disable rental
if not area_rent.metadata:contains("center") then
    --Log entry...
    area_rent.metadata:set_int("setup",0) -- TODO add entry for all commands that tells us to set center
else
    local meta_center_pos = area_rent.metadata:get_string("center")
    area_rent.origin = minetest.deserialize(meta_center_pos)
end

--Limit and inflation
-- We need to keep track of how many properties or the amount of the map
-- These settings should be configured in the settings section of minetest 
area_rent.limit = {
    vrt_ratio = .3,
    hrz_ratio = .3,
    h_min = 20, -- Min height 
    w_max = 20, -- Max Width
    nodes.base = 8000,
    


}
area_rent.limit.price.inflation = .15  -- Inflate the price for more then count limit
area_rent.limit.price.base = 100
area_rent.limit.areas = 2
area_rent.limit.inflation = .15
area_rent.price.center = 5
area_rent.price.per.node.radius = 2000
area_rent.price.outer = .0125
area_rent.price.per.area = 2








--Oragin
area_rent.infl_oragin = 0.15
