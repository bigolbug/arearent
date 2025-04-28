
core.register_chatcommand("rent", {
	params = "[action] [area ID]",
	description = "Use status, area or nothing to manage, rent and check rental area\n"..
	"Example: \n"..
	"type /rent          to find out details about your rental area\n"..
	"type /rent area     to rent an area\n"..
	"type /rent status   for an update on your properties\n"..
	"type /rent pos   	 to set the second area marker\n"
	,
	func = function(name, param)
		-- define a local variables
		local params = param:gmatch("([%a%d_]+)")
		local action, area_ID = params(1), params(2)
		if action ~= nil then action = string.upper(action) end
		local player = core.get_player_by_name(name)
		if player == nil then
			return false, name .. " is not currently active in the game"
		end
		local player_meta = player:get_meta()
		local player_rent = player_meta:get_int("rent")
		local pos = player:get_pos()
		local XP = xp_redo.get_xp(name)
		local area_data = {}
		area_data["pos1"], area_data["pos2"] = areas:getPos(name)
		area_data["owner"] = "SERVER"
		area_data["loaner"] = name
		area_data["cost"] = nil
		area_data["time"] = os.time()

		if action == "STATUS" then
			local message = "You have "..XP.." xp. "
			if XP > 1000000 then
				message = message .. "You might need to get a life, this is just Luanti"
			elseif XP > 10000 then
				message = message .. "Pathetic really, let's be honest"
			elseif XP > 5000 then
				message = message .. "Officially, level slacker"
			else

			end
			local cued_Areas = area_rent.areas_by_player(name,"CUED")
			local Rented_Areas = area_rent.areas_by_player(name,"RENTED")
	
			--core.chat_send_all(Rented_table_Len)
			if area_rent.tableLen(Rented_Areas) then
				message = message .. "\n\tYour rented areas are..."
				local Total_cost = 0
				for Area_Name, Area_desc in pairs(Rented_Areas) do
					local area_data = core.deserialize(Area_desc)
					Total_cost = Total_cost + area_data.cost
					message = message .. "\n\t" .. Area_Name
				end
				-- !!! Here is a good place to check for discrepencies between player_rent and total_cost
				message = message .. "\n\tCosting: " .. Total_cost .. " xp per day"
			else
				message = message .. "\n\tYou have no properties rented"
			end

			if area_rent.tableLen(cued_Areas) then
				message = message .. "\n\tYour cued areas are..."
				for Area_Name, Area_description in pairs(cued_Areas) do
					message = message .. "\n\t" .. Area_Name
				end
			else
				message = message .. "\n\tYou have no properties cued"
			end

			return false, message
		elseif action == "POS"  then	
			-- Check to see if an area needs to be selected. 
			local player = core.get_player_by_name(name)
			local pos = vector.round(player:get_pos())
			pos.y = pos.y-1
			areas:setPos1(name, pos)

			local limit = {}
			limit.x = area_rent.limit.w_max
			limit.z = area_rent.limit.w_max
			limit.y = math.floor(area_rent.limit.volume/(limit.x*limit.z))
			
			local pos = vector.add(pos,limit)

			areas:setPos2(name, pos)
			return true, "The second location has been set"
		elseif action == "AREA"  then
			--validate cue
			local meta_table = area_rent.metadata:to_table()
			local area_descriptor = meta_table["fields"][area_ID]
			if not area_descriptor then
				return false, area_ID .. " is not a known cue. \n\t\t Use --> /rent status <-- to see your cued areas"
			end
			area_data = core.deserialize(area_descriptor)
			if os.time() - area_data.time > area_rent.cue_expiration then
				if not area_rent.qualify(name,XP,area_data.cost) then
					local total_rent = player_rent + area_data.cost
					local qualifying_XP = area_rent.qualifying_term * total_rent
					local XP_difference = qualifying_XP - XP
					return false, "You no longer qualify for this area. You need "..XP_difference.." more XP. Increase your XP and try again"
				end
				area_data.time = os.time()
			end

			--remove Que
			meta_table["fields"][area_ID] = nil
			area_rent.metadata:from_table(meta_table)

			area_rent.rent_area(area_data,name)
			return false, "Rental complete"
		elseif action == "VIEW" then
			local player = core.get_player_by_name(name)
			local pos = vector.round(player:get_pos())
			if not area_ID then
				local player_areas = area_rent.areas_by_player(name)
				local message = "What area would you like to view?\n"
				for area_name, area_desc in pairs(player_areas) do
					message = message .. "\t\t"..area_name.."\n"
				end
				return false, message
			end

			local area_desc = area_rent.metadata:get_string(area_ID)
			if not area_desc then
				return false, area_ID .. " is not a known area. \n\t\t Use --> /rent status <-- to see your areas"
			end
			
			if true then
				core.chat_send_all(type(area_desc))
				if type(area_desc) == "table" then
					for key, value in pairs(area_desc) do
						core.chat_send_all(key)
					end
				end
				return false," investigation complete"
			end
			area_desc = core.deserialize(area_desc)
			
			if area_desc.owner ~= name then
				return false, "You can not view this area since you are not the owner"
			end
			local entity = core.add_entity(pos, "area_rent:boarder")
			--[[
			if entity then
				local luaentity = entity:get_luaentity()
				if luaentity then
					luaentity.player = name
				end
			end
			]]
		elseif action == "REMOVE" then
			if not tonumber(area_ID) then
				return false, "you must specify the area by ID number"
			end 
			local ID = tonumber(area_ID)
			--Is the sender the owner?
			if not areas:isAreaOwner(ID, name) then
				return false, "You must be the owner of the area to remove it"
			end

			local area_name = area_rent.get_area_by_ID(ID,name)
			if not area_name then
				-- This owner does not have an area by that ID
				return false, "You do not have an area with that ID number"
			end

			area_rent.metadata:set_string(area_name,nil)
			areas:remove(ID)
			areas:save()
			return true, "Area ".. area_name.." with ID ".. ID .. " has been removed. Check /rent Status to cofirm"

		elseif action == nil then
			-- Check to see if mod is enabled
			local ar_center = core.deserialize(area_rent.metadata:get_string("center"))
			if not ar_center then
				return false, "Area rent mod is not setup, please set a center with /rdata center"
			end

			-- Check to see if an area needs to be selected. 
			if not (area_data.pos1 and area_data.pos2) then
				return false, "You need to select an area first. Use /area_pos1 \nand /area_pos2 to set the bounding corners"
			end
			
			--Check for intersecting areas and determine action. 
			local intersecting_areas = areas:getAreasIntersectingArea(area_data.pos1, area_data.pos2)
			--This is were you would find out if the player owns the area. 
			if #intersecting_areas > 0 then
				return false, "At this time you can not rent this area since it intersects with another"
			end

			--Check to make sure the area is the correct shape
			local area_height = math.abs(area_data.pos1.y - area_data.pos2.y)
			local area_dx = math.abs(area_data.pos1.x - area_data.pos2.x)
			local area_dz = math.abs(area_data.pos1.z - area_data.pos2.z)
			
			if area_rent.greifer_check(area_dx,area_height,area_dz,area_data.loaner) then
				return false, "Please reselect an area and try /rent again"
			end

			--Calculate Volume
			area_data.volume = area_height * area_dx * area_dz
			if area_data.volume > area_rent.limit.volume then return false, "Please reduce the size of your selection" end

			-- CALCULATE RENTAL PRICE
			-- find distance from area center to the universal center
			local area_center = area_rent.center_pos(area_data.pos1,area_data.pos2)
			local distance_to_center = vector.distance(ar_center, area_center)
			local rate = area_rent.price.rate(distance_to_center)
			area_data.cost = math.ceil(rate * area_data.volume)
			core.chat_send_player(name,"This area will cost: ".. area_data.cost .. " xp per day\n\tArea priced at "..rate.." xp per node per day")
			
			--Based on your current XP...
			if not area_rent.qualify(area_data.loaner,XP,area_data.cost) then
				return false, "You have ".. XP.." XP. which is insufficient XP to rent this area\n"..
					"You must be able to cover the cost of your properties for up to ".. area_rent.qualifying_term.." days"
			end
			
			--Save the area in mod storage and inform the user on how to recall it. 
			local message = ""
			local area_name = area_rent.cue_Area(area_data)
			message = message .. "\n\tThe area you have cued is called " .. area_name
			message = message .. "\n\tThe following is the command for renting this area"
			message = message .. "\n\t/rent area "..area_name
			core.chat_send_player(name,message)



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
		else
			core.chat_send_all("Action Variable Value: -->"..action.."<--")
			return false, "I'm sorry, you have used /rent incorrectly. For more info please use --> /help all"
		end
	end
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

core.register_chatcommand("rcmd",{
	params = "[action]",
	privs = "server",
	description = "Check the data of the Area Rental Mod: Options: clear, center and none for all data",
	func = function(name, param)
		local action = string.upper(param)
		if action == "CLEAR" then
			local meta_data = area_rent.metadata:to_table()
			for area_name, area_desc in pairs(meta_data["fields"]) do
				local digits = string.gmatch(area_name,"[%d]+")
				if digits then
					core.chat_send_all("removing "..area_name.."           ".. area_desc)	
					meta_data["fields"][area_name] = nil
				end
				
			end
			area_rent.metadata:from_table(meta_data)
		elseif action == "CENTER" then
			local player = core.get_player_by_name(name)
			local center = core.serialize(player:get_pos())
			area_rent.metadata:set_string("center",center)
			area_rent.metadata:set_int("setup",1)
			area_rent.debug("Set the area rent center to "..center)
		elseif action == "CHARGE" then
			if not area_rent.charge() then
				return false, "You can only charge once per day."
			end
			return false, "You have successfully charged rent"
		else
			local meta_data = area_rent.metadata:to_table()
			for area_name, area_desc in pairs(meta_data["fields"]) do
				core.chat_send_all(area_name.."           ".. area_desc)
			end
			core.chat_send_player(name,"Running default RCMD")
		end
		
	end,

})