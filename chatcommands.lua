
minetest.register_chatcommand("rent", {
	params = "",
	description = "TBD, something to do with renting an area",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		local pos1, pos2 = areas:getPos(name)

		if not (pos1 and pos2) then
			return false, "You need to select an area first. Use /area_pos1 \nand /area_pos2 to set the bounding corners"
		end
		
		--Check for intersecting areas and determine action. 
		local intersecting_areas = areas:getAreasIntersectingArea(pos1, pos2)
		if #intersecting_areas > 0 then
			return false, "At this time you can not rent this area since it intersects with another"
		end

		-- CALCULATE RENTAL PRICE
		-- find distance from area center to the universal center
		local area_center = area_rent.center_pos(pos1,pos2)
		local distance_to_center = vector.distance(area_rent.origin, area_center)
		--local radius = {x = area_rent.origin.x - area_center.x, y = area_rent.origin.y - area_center.y, z = area_rent.origin.z - area_center.z}
		
		

		--local area_center = vector

		if area_id then
			-- is the player already the owner?
			local area = areas.areas[area_id]
			return false, "Your selection itersects with another players area"
		end


		
	end,
})

minetest.register_chatcommand("booyah", {
	params = "[PlayerName]",
	description = "Committal statement to rental selection and agreement",
	func = function(name, param)
		local ownerName = param
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		
		-- Check to see if PlayerName is valid
		if not areas:player_exists(name) then
			return false, S("The player \"@1\" does not exist.", ownerName)
		end

		--Check to see of we can bypass limits
		if name and minetest.check_player_privs(name, "server") then 
			return true, "You are an admin"
		end



	end,
})

minetest.register_chatcommand("rent_area_center",{
	params = "",
	privs = "server",
	description = "Set the center of the rental area",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local center = minetest.serialize(player:get_pos())
		area_rent.metadata:set_string("center",center)
		area_rent.metadata:set_int("setup",1)
	end,

})