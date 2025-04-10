
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
			
			local storage_table = area_rent.metadata:to_table()
			for key, value in pairs(storage_table["fields"]) do
				core.chat_send_all(key)
			end

			return false, message
		end

		-- Check to see if an area needs to be selected. 
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
		local rate = area_rent.price.rate(distance_to_center)
		local cost = math.ceil(rate * area_vol)
		core.chat_send_player(name,"This area will cost: ".. cost .. " xp per day\n\tArea priced at "..rate.." xp per node per day")
		
		--Based on your current XP...
		if area_rent:qualify(XP,cost) then
			-- You qualify
		else
			return false, "You have ".. XP.." XP. which is insufficient XP to rent this area\n"..
				"You must be able to cover the cost of all your properties for up to a month before qualifying for a new property"
		end
		local rental_life = math.floor(XP/cost)
		
		

		--Save the area in mod storage and inform the user on how to recall it. 
		local message = "You are able to store up to 5 areas for recall"
		local area_name = area_rent.Que_Area(pos1,pos2,name,cost)
		message = message .. "\n" .. "\tThe Area you have qued is called " .. area_name
		message = message .. "\n" .. "\tThe following is the command for renting this area"
		local player_areas = area_rent.area_count(name)

		
		--[[
		if not area_rent.metadata:contains(name) then
			--The player has no areas stored
			local area_name = name .. "_" .. os.time()
			player_Meta[name] = { fields = {}}
			player_Meta[name]["fields"][area_name] = area_rent.serialize(pos1, pos2, name, cost)
			if mod_storage:from_table(player_Meta[name]) then
				core.chat_send_all("Success")
			end
			core.chat_send_all("No entry")
		else
			core.chat_send_all("Found Entry")
		end
		]]--
	
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