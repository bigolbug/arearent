
core.register_chatcommand("rent", {
	params = "[action] [area ID]",
	description = "Use status, area or nothing to manage, rent and check rental area\n"..
	"Example: \n"..
	"type /rent          	to find out details about your rental area\n"..
	"type /rent area     	to rent an area\n"..
	"type /rent status   	for an update on your properties\n"..
	"type /rent pos X,Y,Z  	to set the area markers. exclude X,Y,Z to select default area, set to 0 to use defaults\n"..
	"type /rent    	 		to set the second area marker\n"
	,
	func = function(name, param)
		-- define a local variables
		local params = param:gmatch("([%a%d_,]+)")
		local action, area_ID = params(1), params(2)
		if action ~= nil then action = string.upper(action) end
		local player = core.get_player_by_name(name)
		if player == nil then
			return false, name .. " is not currently active in the game"
		end
		local player_meta = player:get_meta()
		local player_rent = player_meta:get_int("rent")
		local pos = player:get_pos()
		local XP = area_rent.metadata:get_int(name.."XP")
		local area_data = {}
		area_data["pos1"], area_data["pos2"] = areas:getPos(name)
		area_data["owner"] = "SERVER"
		area_data["loaner"] = name
		area_data["cost"] = nil
		area_data["time"] = tostring(os.time())

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
			local cued_Areas = area_rent.get_areas_by_player(name,"CUED")
			local Rented_Areas = area_rent.get_areas_by_player(name,"RENTED")
	
			--core.chat_send_all(Rented_table_Len)
			if area_rent.tableLen(Rented_Areas) then
				message = message .. "\n\tYour rented areas are..."
				local Total_cost = 0
				for Area_Name, Area_desc in pairs(Rented_Areas) do
					Total_cost = Total_cost + Area_desc.cost
					message = message .. "\n\t\t\tArea ID: " .. Area_desc.ID.. " with name ".. Area_desc.name
				end
				-- !!! Here is a good place to check for discrepencies between player_rent and total_cost
				message = message .. "\n\t\tCosting: " .. Total_cost .. " xp per day"
			else
				message = message .. "\n\tYou have no properties rented"
			end

			if area_rent.tableLen(cued_Areas) then
				message = message .. "\n\tYour cued areas are..."
				for Area_Name, Area_description in pairs(cued_Areas) do
					message = message .. "\n\t\t\t" .. Area_description.name
				end
			else
				message = message .. "\n\tYou have no properties cued"
			end

			return true, message
		elseif action == "POS"  then	
			-- Check to see if an area needs to be selected. 
			local player = core.get_player_by_name(name)
			local pos = vector.round(player:get_pos())
			local offset = {x=-1,y=-1,z=-1}
			pos = vector.add(pos,offset)
			local limit = {}

			if area_ID then
				local found, _, x, y, z = area_ID:find(
				"^(-?%d*)[,](-?%d*)[,](-?%d*)$")

				if found then
					x=tonumber(x) z=tonumber(z) y=tonumber(y)
					if not (x and y and z) then
						return false, "Your X,Y,Z is wrong. Please adjust and retry"
					end
					if x > area_rent.limit.w_max then x = area_rent.limit.w_max end
					if z > area_rent.limit.w_max then z = area_rent.limit.w_max end
					if x == 0 and z == 0 and y ~= 0 then 
						local width = area_rent.limit.volume/(y)
						x = math.floor(math.sqrt(width)) 
						z = math.floor(math.sqrt(width)) 
					elseif x == 0 and z == 0 and y == 0 then 
						x = area_rent.limit.w_max
						z = area_rent.limit.w_max
						y = math.floor(area_rent.limit.volume/(x*z))
					elseif x == 0 and y ~= 0 then
						x = math.floor(area_rent.limit.volume/(z*y))
						if x > area_rent.limit.w_max then x = area_rent.limit.w_max end
						if x < 3 then
							return false, "Sorry your Z or Y is to big, try again with smaller values"
						end
					elseif z == 0 and y ~= 0 then
						z = math.floor(area_rent.limit.volume/(x*y))
						if z > area_rent.limit.w_max then z = area_rent.limit.w_max end
						if z < 3 then
							return false, "Sorry your X or Y is to big, try again with smaller values"
						end
					elseif x == 0 and y == 0 and z ~=0 then
						x = area_rent.limit.w_max
						y = math.floor(area_rent.limit.volume/(x*z))
					elseif x ~= 0 and y == 0 and z == 0 then
						z = area_rent.limit.w_max
						y = math.floor(area_rent.limit.volume/(x*z))
					elseif y == 0 then
						y = math.floor(area_rent.limit.volume/(x*z))
					end
				else
					return false,"Please write your area size as X,Y,Z. Y is height. Alternatively leave off to set default size"
				end

				if x == 0 or z == 0 or y == 0 then
					return false, "Sorry something went wrong please report your command to the admin"
				end

				limit.x = x
				limit.y = y
				limit.z = z
			else
				limit.x = area_rent.limit.w_max
				limit.z = area_rent.limit.w_max
				limit.y = math.floor(area_rent.limit.volume/(limit.x*limit.z))
			end
			
			areas:setPos1(name, pos)
			local pos = vector.add(pos,limit)
			areas:setPos2(name, pos)
			return true, "Selection complete"
		elseif action == "AREA"  then
			--validate cue
			local cued_Areas = core.deserialize(area_rent.metadata:get_string("CUED"))
			if not cued_Areas then
				area_rent.debug("Oops. There are no Cues in meta data")
			end
			if not cued_Areas[name] then
				return false, name .. " does not have any cued areas\n\t\t Use --> /rent <-- to cue an area"
			end
			local area_desc = area_rent.get_area_by_name(area_ID,name)
			if not area_desc then
				return false, "You might have missspelled the area name. \n\t\t Use --> /rent status <-- to see your cued areas"
			end
			
			local area_ID = area_desc.time

			if os.time() - area_desc.time > area_rent.cue_expiration then
				-- CUE Has expired
				if not area_rent.qualify(name,XP,area_desc.cost) then
					local total_rent = player_rent + area_desc.cost
					local qualifying_XP = area_rent.qualifying_term * total_rent
					local XP_difference = qualifying_XP - XP
					return false, "You no longer qualify for this area. You need "..XP_difference.." more XP. Increase your XP and try again"
				end
				area_desc.time = os.time()
			end

			--Remove Que
			cued_Areas[name][area_ID] = nil
			area_rent.metadata:set_string("CUED",core.serialize(cued_Areas))


			--Create the new area
			area_rent.rent_area(area_desc,name)
			return true, "Rental complete"
		elseif action == "VIEW" then
			local player = core.get_player_by_name(name)
			local pos = vector.round(player:get_pos())
			local player_areas = area_rent.get_areas_by_player(name)
			local viewable_areas = {}
			for area_name, area_desc in pairs(player_areas) do
				local area_center = area_rent.center_pos(area_desc.pos1,area_desc.pos2)
				local distance = vector.distance(pos, area_center)
				if distance < area_rent.limit.viewable_dist then
					viewable_areas[area_name] = area_desc
				end
			end

			if not area_ID then
				if not area_rent.tableLen(viewable_areas)then
					return false, "You either have no properties to view or none are close enough to view"
				end

				local message = "What area would you like to view?\n"
				for area_name, area_desc in pairs(viewable_areas) do
					if tonumber(area_name) then
						message = message .. "\t\t"..area_desc.name.."\n"
					else
						message = message .. "\t\t"..area_name.."\n"
					end
					
				end
				return false, message
			end

			local area_desc = area_rent.get_area_by_name(area_ID,name)

			if not area_desc then
				return false, area_ID .. " is not a known area. \n\t\t Use --> /rent status <-- to see your areas"
			end

			if area_desc.loaner ~= name then
				area_rent.debug(name .. " is trying to view "..area_desc.loaner .. "'s property called "..area_desc.name)
				return false, "You can not view this area since you are not the owner"
			end

			-- create a border
			local pos1 = area_desc.pos1
			local pos2 = area_desc.pos2
			local dx = pos2.x - pos1.x
			local dy = pos2.y - pos1.y
			local dz = pos2.z - pos1.z
			local epos = {}
			local border_list = core.deserialize(area_rent.metadata:get_string("border_list"))
			local current_time = os.time()
			local border_name = name..current_time
			local entity
			if not border_list then
				border_list = {}
			end
			border_list[border_name] = {}

			for y = 0, dy, 2 do
				for x = 0, dx, 1 do
					for z = 0, dz, 1 do
						if x+pos1.x == pos1.x then
							--Faces the negative X Direction
							epos.x = pos1.x
							epos.y = pos1.y + y
							epos.z = pos1.z + z
							entity = core.add_entity(epos, "area_rent:border_NX")
							table.insert(border_list[border_name],core.serialize(epos))
						elseif x+pos1.x == pos2.x then
							--Faces the Posative X Direction
							epos.x = pos2.x
							epos.y = pos1.y + y
							epos.z = pos1.z + z
							entity = core.add_entity(epos, "area_rent:border_PX")	
							table.insert(border_list[border_name],core.serialize(epos))
						elseif z+pos1.z == pos1.z then
							--Faces the eposative X Direction
							epos.x = pos1.x + x
							epos.y = pos1.y + y
							epos.z = pos1.z
							entity = core.add_entity(epos, "area_rent:border_NZ")	
							table.insert(border_list[border_name],core.serialize(epos))
						elseif z+pos1.z == pos2.z then
							--Faces the eposative X Direction
							epos.x = pos1.x + x
							epos.y = pos1.y + y
							epos.z = pos2.z
							entity = core.add_entity(epos, "area_rent:border_PZ")	
							table.insert(border_list[border_name],core.serialize(epos))
						end
					end
				end
				
			end

			area_rent.metadata:set_string("border_list",core.serialize(border_list))
			core.after(area_rent.border_experation,area_rent.clear_border,border_name)

		elseif action == "REMOVE" then
			local rented_properties = core.deserialize(area_rent.metadata:get_string("RENTED"))
			if not rented_properties then
				return false, "There are no properties to remove"
			end

			local ID = tonumber(area_ID)
			if not ID then
				return false, "you must specify the area by ID number"
			end 
			
			--Is the sender the owner?
			if not areas:isAreaOwner(ID, name) then
				return false, "You must be the owner of the area to remove it"
			end

			local area_name = area_rent.get_area_by_ID(ID,name)
			if not area_name then
				-- This owner does not have an area by that ID
				return false, "You do not have an area with that ID number"
			end

			rented_properties[name][area_name] = nil
			area_rent.metadata:set_string("RENTED",core.serialize(rented_properties))
			areas:remove(ID)
			areas:save()
			return true, "Area ".. area_name.." with ID ".. ID .. " has been removed. Check /rent Status to cofirm"

		elseif action == nil then
			-- Check to see if mod is enabled
			local ar_center = core.deserialize(area_rent.metadata:get_string("center"))
			if not ar_center then
				return false, "Area rent mod is not setup. Ask your admin to set a center with /rcmd center"
			end

			-- Check to see if an area needs to be selected. 
			if not (area_data.pos1 and area_data.pos2) then
				return false, "You need to select an area first. Use /area_pos1 \nand /area_pos2 to set the bounding corners"
			end
			
			--Check for intersecting areas and determine action. 
			local intersecting_areas = areas:getAreasIntersectingArea(area_data.pos1, area_data.pos2)
			area_rent.debug("There are ".. #intersecting_areas .. " intersecting araes")
			area_rent.debug("intersecting araes variable type: "..type(#intersecting_areas))
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

			if area_ID then
				-- is the player already the owner?
				local area = areas.areas[area_ID]
				return false, "Your selection itersects with another players area"
			end
		else
			core.chat_send_all("Action Variable Value: -->"..action.."<--")
			return false, "I'm sorry, you have used /rent incorrectly. For more info please use --> /help all"
		end
	end
})

core.register_chatcommand("rcmd",{
	params = "[action] [data]",
	privs = "server",
	description = "Check the data of the Area Rental Mod: Options: clear, center and none for all data",
	func = function(name, param)
		local params = param:gmatch("([%a%d_,]+)")
		local action, data = params(1), params(2)
		if action ~= nil then action = string.upper(action) end

		if action == "CLEAR" then
			local meta_data = area_rent.metadata:to_table()

			if data then
				if meta_data.fields[data] then
					meta_data.fields[data] = nil
				else
					return false, "You may have missspelled your data type"	
				end
			else
				for area_name, area_desc in pairs(meta_data["fields"]) do
					local digits = string.gmatch(area_name,"[%d]+")
					if digits then
						core.chat_send_all("removing "..area_name.."           ".. area_desc)	
						meta_data["fields"][area_name] = nil
					end
					
				end
			end
			area_rent.metadata:from_table(meta_data)
		elseif action == "CENTER" then
			local player = core.get_player_by_name(name)
			local center = core.serialize(player:get_pos())
			area_rent.metadata:set_string("center",center)
			area_rent.metadata:set_int("setup",1)
			area_rent.debug("Set the area rent center to "..center)
		elseif action == "XP" then
			if not tonumber(data) then
				return false, "You need to enter a number"
			end
			
			area_rent.updateXP(name,data)
		elseif action == "XP_DEBUG" then
			return true, "Your XP from XP redo: " .. xp_redo.get_xp(name)
		elseif action == "CUED" then
			core.chat_send_player(name,"Accessing CUED Data")
			local cued_areas = core.deserialize(area_rent.metadata:get_string("CUED")) 
			if not cued_areas then
				return false, "Can't access cued data"
			end
			for player, area in pairs(cued_areas) do
				core.chat_send_player(name,player.." has cued data. Their properties are")
				for area_name, area_data in pairs(area) do
					core.chat_send_player(name,area_name .. " with name "..area_data.name)
				end
			end
			return true
		elseif action == "RENTED" then
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