
core.register_chatcommand("rent", {
	params = "[action]",
	description = "Use status, area or nothing to manage, rent and check rental area\n"..
	"Example: \n"..
	"type /rent          to find out details about your rental area\n"..
	"type /rent area     to rent an area\n"..
	"type /rent status   for an update on your properties\n"
	,
	func = function(name, param)
		local action = string.upper(param)
		local player = core.get_player_by_name(name)
		local pos = player:get_pos()
		local XP = xp_redo.get_xp(name)
		local pos1, pos2 = areas:getPos(name)

		if action == "STATUS" then
			local message = "Player XP: "..XP.."\n"
			local sound = {
				name = "arearent-notification.ogg",
				gain = 1,
				pitch = 1,
				fade = 1,
			}
			core.sound_play(sound)

			return false, "message"
		end

		if not (pos1 and pos2) then
			return false, "You need to select an area first. Use /area_pos1 \nand /area_pos2 to set the bounding corners"
		end
		
		--Check for intersecting areas and determine action. 
		local intersecting_areas = areas:getAreasIntersectingArea(pos1, pos2)
		if #intersecting_areas > 0 then
			return false, "At this time you can not rent this area since it intersects with another"
		end

		--Check to make sure the area is the correct shape
		local area_height = math.abs(pos1.y - pos2.y)
		local area_dx = math.abs(pos1.x - pos2.x)
		local area_dz = math.abs(pos1.z - pos2.z)
		
		if area_rent.greifer_check(area_dx,area_height,area_dz,name) then
			return false, "Please reselect an area and try /rent again"
		end

		--Calculate Volume
		local area_vol = area_height * area_dx * area_dz
		if area_vol > area_rent.limit.volume then return false, "Please reduce the size of your selection" end

		-- CALCULATE RENTAL PRICE
		-- find distance from area center to the universal center
		local area_center = area_rent.center_pos(pos1,pos2)
		local distance_to_center = vector.distance(area_rent.origin, area_center)

		core.chat_send_player(name,"Distance From center: "..distance_to_center)

		--Apply a rate 


	
		--local radius = {x = area_rent.origin.x - area_center.x, y = area_rent.origin.y - area_center.y, z = area_rent.origin.z - area_center.z}
		
		

		--local area_center = vector

		if area_id then
			-- is the player already the owner?
			local area = areas.areas[area_id]
			return false, "Your selection itersects with another players area"
		end


		
	end,
})
--[[
core.register_chatcommand("booyah", {
	params = "[PlayerName]",
	description = "Committal statement to rent selection and agreement",
	func = function(name, param)
		local ownerName = param
		local player = core.get_player_by_name(name)
		local pos = player:get_pos()
		
		-- Check to see if PlayerName is valid
		if not areas:player_exists(name) then
			return false, S("The player \"@1\" does not exist.", ownerName)
		end

		--Check to see of we can bypass limits
		if name and core.check_player_privs(name, "server") then 
			return true, "You are an admin"
		end



	end,
})
]]--
core.register_chatcommand("rent_area_center",{
	params = "",
	privs = "server",
	description = "Set the center of the rental area",
	func = function(name, param)
		local player = core.get_player_by_name(name)
		local center = core.serialize(player:get_pos())
		area_rent.metadata:set_string("center",center)
		area_rent.metadata:set_int("setup",1)
		
		core.chat_send_player(name,"Set the area rent center to")
		
	end,

})