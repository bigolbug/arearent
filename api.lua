area_rent.whose = function()
end
area_rent.available = function()
end
area_rent.clip = function(area)
    local pos1 = area.pos1
    local pos2 = area.pos2
    
    return true
end

-- Check to see if user is admin
function area_rent.admin(name,priv)
    if core.check_player_privs(name,priv) then
        return true
    end
    return false
end

function area_rent.center_pos(pos1,pos2)
    local v1 = vector.new(pos1)
    local v2 = vector.new(pos2)
    local average = (v1 + v2)/2

    return average
end

function area_rent.greifer_check(x,y,z,player)

    local ratio_vert = 0
    local ratio_horz = 0

    if x > z then
        -- z is smaller
        ratio_horz = z / x
        ratio_vert = y / z
        
    else
        -- x is smaller
        ratio_horz = x / z
        ratio_vert = y / x
    end

    --core.chat_send_all("height ratio: "..ratio_vert .. " horizontal ratio ".. ratio_horz)
    if ratio_horz < area_rent.limit.hrz_ratio and x < area_rent.limit.w_min or z < area_rent.limit.w_min then
        core.chat_send_player(player,"Your selection is to narrow")
        return true    
    end

    if y > area_rent.limit.h_max then
        core.chat_send_player(player,"Your selection is ".. area_rent.limit.h_max - y .." blocks to tall")       
        return true
    elseif y < area_rent.limit.h_min then
        core.chat_send_player(player,"Your selection is ".. area_rent.limit.h_min - y .." blocks to short")            
        return true    
    end

    if ratio_vert > area_rent.limit.vrt_ratio then
        core.chat_send_player(player,"Your selection is to tall")
        return true
    end
    

end

function area_rent.cue_Area(area_data)
    --[[
    --Use this code if you want the abreviation of the player
    local _ = string.find(area_data.loaner,"_")
    local player_abrev  = ""
    if _ then 
        --First Initial Last Initial
        player_abrev = string.sub(area_data.loaner,1,1)..string.sub(area_data.loaner,_+1,_+1) 
    else
        --First two initials
        player_abrev = string.sub(area_data.loaner,1,2)
    end
    local time_abrev = string.gmatch(tostring(os.time()),"(%d%d%d)$")
    local area_name = player_abrev .. time_abrev(1)
    ]]

    area_data.name = area_rent.adj[math.random(#area_rent.adj)] .. 
    "_" .. area_rent.noun[math.random(#area_rent.noun)] .. 
    "_" .. area_rent.formation[math.random(#area_rent.formation)]
    
    --Check for stale areas
    local cued_Areas = area_rent.get_areas_by_player(area_data.loaner, "CUED")

    local cued_list = core.deserialize(area_rent.metadata:get_string("CUED"))

    if not cued_list[area_data.loaner] then
        cued_list[area_data.loaner] = {}
    end
    cued_list[area_data.loaner][area_data.time] = area_data

    area_rent.metadata:set_string("CUED", core.serialize(cued_list))
    return area_data.name
end

function area_rent.get_area_by_name(search_name,owner,category)
    local cued_Areas = core.deserialize(area_rent.metadata:get_string("CUED"))
    local rented_Areas = core.deserialize(area_rent.metadata:get_string("RENTED"))

    if not category then
        if rented_Areas[owner] then
            for area_name, area_des in pairs(rented_Areas[owner]) do
                if area_des.name == search_name then
                    return area_des
                end
            end
        end
        
        if cued_Areas[owner] then
            for area_name, area_des in pairs(cued_Areas[owner]) do
                if area_des.name == search_name then
                    return area_des
                end
            end
        end
        return false    
    end

    category = string.upper(category)
    
    if category == "CUED" then
        if cued_Areas[owner] then
            for area_name, area_des in pairs(cued_Areas[owner]) do
                if area_des.name == search_name then
                    return area_des
                end
            end
        end    
    end

    if category == "RENTED" then
        if rented_Areas[owner] then
            for area_name, area_des in pairs(rented_Areas[owner]) do
                if area_des.name == search_name then
                    return area_des
                end
            end
        end    
    end

    return false
end

function area_rent.rent_area(area_data, renter)
    -- Who is renting from who?
    if area_data.loaner ~= renter then
        area_data.owner = area_data.loaner
        area_data.loaner = renter
    end
    
    local renter_list = core.deserialize(area_rent.metadata:get_string("RENTED"))

    if not renter_list then
        renter_list = {}
    end
    
    if not renter_list[renter] then
        renter_list[renter] = {}
    end
    
    -- update area time to current time
    area_data.time = tostring(os.time())

    --Create the area in the Areas mod
    area_data.ID = areas:add(area_data.loaner, area_data.name, area_data.pos1, area_data.pos2, nil)
    areas:save()

    renter_list[renter][area_data.time]=area_data

    area_rent.metadata:set_string("RENTED",core.serialize(renter_list))

    local last_day_charged = area_rent.metadata:get_int("last_charge_day")
    if last_day_charged == 0 then
        area_rent.metadata:set_int("last_charge_day",core.get_day_count())
        area_rent.debug("Initializing last_day_charge in Metadata")
    end

    return true
end

function area_rent.add_zeros(number)
    local len = string.len(number)
    local text = ""
    for i = 1, 8 - len, 1 do
        text = text .. "0"
    end
    return text .. number
end

function area_rent.sort(TBL,catagory)
    --[[
    This functin lacks intelegance for the sack of simplicity. It should 
    determine whether a catagory is a number of string before sorting
    ]]--
    local sort_areas = {}
    
    -- To see available catagories check... 
    if catagory then 
        --sort based on catagory
        for area_name, area_desc in pairs(TBL) do
            if not area_desc[catagory] then
                core.log("error","The Area Rent mod failed in the sort function, catagory not found")
                return false
            end
            local prefix = area_rent.add_zeros(area_desc[catagory])
            area_name = prefix ..".".. area_name
            table.insert(sort_areas, area_name)
        end
        table.sort(sort_areas)
        --Strip the catagory
        for i, area_name in ipairs(sort_areas) do
            sort_areas[i] = string.gsub (area_name,"^%d+%.","")
        end
    else
        --Sort table, newest to oldest
        for area_name, area_des in pairs(TBL) do 
            table.insert(sort_areas, area_name) 
        end
        table.sort(sort_areas)
    end    

    return sort_areas
end

function area_rent.areas_by_player()
    core.chat_send_all("There is still a function using the old areas by player function")
    return false
end

function area_rent.get_areas_by_player(player, Status)
    local TBL = {}
    local rented_areas = core.deserialize(area_rent.metadata:get_string("RENTED"))
    local cued_areas = core.deserialize(area_rent.metadata:get_string("CUED"))
    
    if Status then Status = string.upper(Status) end
    if not rented_areas then rented_areas = {} end
    if not cued_areas then cued_areas = {} end
    
    if not Status then
        -- No status was specified, using both rented and cued
        local RENTED = rented_areas[player]
        if RENTED then
            for area_ID, area_data in pairs(RENTED) do
                TBL[area_ID] = area_data -- The area data on this is already deserialized
            end    
        end
        
        local CUED = cued_areas[player]
        if CUED then
            for area_ID, area_data in pairs(CUED) do
                TBL[area_ID] = area_data -- The area data on this is already deserialized
            end
        end
        
    elseif string.upper(Status) == "RENTED" then
        local RENTED = rented_areas[player]
        if RENTED then
            for area_ID, area_data in pairs(RENTED) do
                TBL[area_ID] = area_data -- The area data on this is already deserialized
            end    
        end

    elseif string.upper(Status) == "CUED" then        
        local CUED = cued_areas[player]
        if CUED then
            for area_ID, area_data in pairs(CUED) do
                TBL[area_ID] = area_data -- The area data on this is already deserialized
            end
        end
    end

    if Status == "CUED" then
        local sorted_areas = area_rent.sort(TBL)
        area_rent.debug("Looks like we have "..#sorted_areas.." cued areas")
        -- If there are 5 or more then update Meta data
        while #sorted_areas > area_rent.cueable_Area_Limit do
            cued_areas[player][sorted_areas[1]] = nil
            TBL[sorted_areas[1]] = nil
            table.remove(sorted_areas,1)
        end 
        area_rent.metadata:set_string("CUED",core.serialize(cued_areas))
    end

    return TBL
end

function area_rent.qualify(qualifying_data,name,term)
    local total_Properties_Cost = 0
    local total_volume = 0
    term = term or area_rent.qualifying_term
    
    if qualifying_data then 
        total_Properties_Cost = qualifying_data.cost 
        total_volume = qualifying_data.volume 
        if not name then
            name = qualifying_data.loaner    
        elseif qualifying_data.loaner ~= name then
            -- the name does not match the loaner of the area specified.
        end
    end

    if not name then
        area_rent.debug("area_data and player name was not specified, there is not way to qualify")
        return false
    end

    local XP = area_rent.metadata:get_int(name.."XP")
    area_rent.debug(name .. " currently has "..XP.." XP")

    -- get all the properties of a player
    local player_properties = area_rent.get_areas_by_player(name,"RENTED")
    
    --Count up the cost for all rentals
    if area_rent.tableLen(player_properties) then
        for area_name,area_data in pairs(player_properties) do
            total_Properties_Cost = total_Properties_Cost + area_data.cost
            total_volume = total_volume + area_data.volume
        end
    end

    --if volume is less then the max
    if total_volume < area_rent.limit.total_volume and total_Properties_Cost * term < XP then
        return true
    end

    area_rent.debug(name.." does not qualify since the property cost of "..total_Properties_Cost .. " exceeds their current XP " ..XP.." for "..term.." day term")
    return false
end

function area_rent.tableLen(TBL)
    local count = 0

    if not TBL then
        area_rent.debug("The table was not passed to the tableLen function")
        return false
    end
    

    for key, value in pairs(TBL) do count = count + 1 end
    if count == 0 then return false else return count end
end

function area_rent.checkMetaDataValues (meta) 
    core.chat_send_all("\n\nChecking Meta Values: Invocation "..os.time().."\n")
    for key, value in pairs(meta["fields"]) do
        core.chat_send_all(value)
    end
end

function area_rent.playsound(file)
			local sound = {
				name = "arearent-notification.ogg",
				gain = 1,
				pitch = 1,
				fade = 1,
			}
			core.sound_play(sound)
end

function area_rent.charge()
    local rentals = core.deserialize(area_rent.metadata:get_string("RENTED"))

    if not rentals then
        --!!! Check to see if there are any areas rented
        area_rent.debug("Renters does not exist in meta data. Renters variable type: "..type(rentals))
        return false
    end

    -- parse through renteres list and charge each
    for renter in pairs(rentals) do
        local player_areas = area_rent.get_areas_by_player(renter,"rented")
        

        --Check to make sure renter can make payment
        while (not area_rent.qualify(nil,renter,2)) and (area_rent.tableLen(player_areas)) do
            area_rent.debug(renter.." can not make payment, removing propery")
            local removed,message = area_rent.remove_area(renter)
            if not removed then
                area_rent.debug("The removal function failed with this message: "..message)
                break
            end
            --area_rent.remove_area(renter) -- Remove the smallest property and try again
            player_areas = area_rent.get_areas_by_player(renter,"rented")
        end

        -- Charge the player if they have properties
        if area_rent.tableLen(player_areas) then
            -- the player has active areas. 
            for area_name,area_desc in pairs(player_areas) do
                area_rent.updateXP(renter, -area_desc.cost)
                area_rent.debug("Charging "..renter.." area cost -$"..area_desc.cost .. " New XP:"..area_rent.metadata:get_int(renter.."XP"))
                if area_desc.owner ~= "SERVER" then
                    area_rent.updateXP(area_desc.owner,area_desc.cost)
                    area_rent.debug("Transfering $"..area_desc.cost .. " to "..area_desc.owner..". New XP:"..area_rent.metadata:get_int(area_desc.owner.."XP"))
                end
            end
        end
    end


    area_rent.metadata:set_int("last_charge_time",os.time())
    area_rent.metadata:set_int("last_charge_day",core.get_day_count())
    return true
end

function area_rent.check_balance(name)
    local cued_Areas = area_rent.get_areas_by_player(name,"CUED")
    local Rented_Areas = area_rent.get_areas_by_player(name,"RENTED")
    local message = ""

    --core.chat_send_all(Rented_table_Len)
    if area_rent.tableLen(Rented_Areas) then
        message = message .. "\n\tYour rented areas are..."
        local Total_cost = 0
        for Area_Name, Area_description in pairs(Rented_Areas) do
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

    return false
end

function area_rent.remove_area(renter,area_name)
    local ID

    if not area_name then
        area_rent.debug("area was not specified. Finding the smallest")
        -- By default, find the smallest
        local player_areas = area_rent.get_areas_by_player(renter,"rented")
        player_areas = area_rent.sort(player_areas,"volume")
        if not player_areas then
            -- this player has no areas to remove. 
            return false, "no properties"
        end
        area_name = player_areas[1]
        area_rent.debug("Found area ".. area_name)
    end

    local rented_areas = core.deserialize(area_rent.metadata:get_string("RENTED"))
    local area_data = rented_areas[renter][area_name]
    if not area_data then
        return false, "area_data"
    end

    ID = area_data.ID

    if not ID then
        -- ID Does not exist. 
        return false, "area_name"
    end

    ID = tonumber(ID)

    if not areas:isAreaOwner(ID, renter) then
        area_rent.debug("The Areas Mod does not agree that "..renter.." is the owner of area ID: "..ID)
        return false, "owner"
    end
    area_rent.debug("Area removal: "..area_name.. " with ID:" .. ID)
    rented_areas[renter][area_name] = nil
    area_rent.metadata:set_string("RENTED",core.serialize(rented_areas))
    areas:remove(ID)
    areas:save()
    return true
end

function area_rent.debug(text)
    core.log(area_rent.debuglevel,text)
end

function area_rent.get_area_by_ID(ID,player)
    local player_areas = area_rent.get_areas_by_player(player,"rented")
    for area_name, area_desc in pairs(player_areas) do
        if area_desc.ID == ID then
            return area_name
        end
    end
    return false
end

function area_rent.test(something)
    if true then
        local message = "Testing variable of type ".. type(something)
        local typ = string.upper(type(something))
        --This does not work as expected
        if typ == "TABLE" then
            message = message .. "\n\t\tHere are the Keys"
            for key, value in pairs(something) do
                message = message .. "\n\t\t\t\t"..key
            end
        elseif typ == "STRING" or typ == "NUMBER" then
            message = message .. " and value ".. something
        elseif typ == "OBJECTREF" then
            -- Nothing to say
        end
        core.chat_send_all(message)
        return false," investigation complete"
    end    
end

function area_rent.clear_border(border)
    local border_list = core.deserialize(area_rent.metadata:get_string("border_list"))
    local positions = border_list[border]
    for index, pos in ipairs(positions) do
        pos = core.deserialize(pos)
        local entitys = core.get_objects_inside_radius(pos, 0)
        if entitys then
            for i, entity in pairs(entitys) do
                if string.upper(type(entity)) == "USERDATA" then
                    entity:remove()
                end
                
            end
        end
    end
    border_list[border] = nil
    area_rent.metadata:set_string("border_list",core.serialize(border_list))
end

function area_rent.updateXP(player,XP)
    --XP will arrive with negative of posative. Posative is add and Negative is remove
    if not XP then
        -- We need to sync XP_redo data with ours
        area_rent.metadata:set_int(player.."XP",xp_redo.get_xp(player)) 
        return true
    end

    if core.get_player_by_name(player) then
        --Online
        local prev_XP = xp_redo.get_xp(player)
        local new_XP = prev_XP + XP
        xp_redo.add_xp(player,XP)
        if new_XP < 0 then 
            area_rent.metadata:set_int(player.."XP",0) 
        else
            area_rent.metadata:set_int(player.."XP",new_XP) 
        end
    else
        --offline
        local prev_XP = area_rent.metadata:get_int(player.."XP")
        local new_XP = prev_XP + XP

        area_rent.debug(player.." is offline. They previously had "..prev_XP.." now they have "..new_XP)
        if new_XP < 0 then
            area_rent.metadata:set_int(player.."XP",0) 
            area_rent.debug(player.. " has negative XP for their new_XP: "..new_XP)
        else
            area_rent.metadata:set_int(player.."XP",new_XP) 
        end    
    end
    return true
end

function area_rent.get_intersecting_areas(area_data)
    local intersecting_areas = {}
    area_rent.debug("Checking for intersecting areas")
    local rentals = core.deserialize(area_rent.metadata:get_string("RENTED"))
    if not rentals then
        rentals = {}
    end

    area_rent.debug(area_data.xz_center_distance.." nodes from center")
    if area_data.xz_center_distance < area_rent.limit.w_max/2 then
        area_rent.debug("We are really close to center and will ignore direction")
        -- We are really close to center and should ignore direction
        for renters, areas in pairs(rentals) do
            for other_area_ID, other_area_data in pairs(areas) do
                if other_area_data.xz_center_distance < area_rent.limit.w_max/2 then
                    --this area is close to center
                    local centers_vector = vector.subtract(area_data.center,other_area_data.center)
                    if math.abs(centers_vector.y) <= area_data.dy/2 + other_area_data.dy/2 then
                        -- check the x and the z
                        area_rent.debug("The area heights are in the same plane ".. area_data.dy/2 + other_area_data.dy/2 .. "dy is greater then centers.y = "..math.abs(centers_vector.y).." ")
                        if math.abs(centers_vector.x)+1 <= area_data.dx/2 + other_area_data.dx/2 and
                            math.abs(centers_vector.z)+1 <= area_data.dz/2 + other_area_data.dz/2
                        then
                            area_rent.debug("There is an area conflict ")
                            area_rent.debug(area_data.dx/2 + other_area_data.dx/2 .. "dx  \t\tcenters.x = "..math.abs(centers_vector.x))
                            area_rent.debug(area_data.dz/2 + other_area_data.dz/2 .. "dz  \t\tcenters.z = "..math.abs(centers_vector.z))
                            intersecting_areas[other_area_ID] = other_area_data    
                            if area_data.loaner ~= other_area_data.loaner then
                                return false
                            end
                        end
                    else
                        area_rent.debug("The area heights are not on the same plane ".. area_data.dy/2 + other_area_data.dy/2 .. "dy is less then centers.y = "..math.abs(centers_vector.y))
                    end
                end
            end
        end
        return intersecting_areas
    end
    area_rent.debug("We are far from center checking all the properties")
    for renters, areas in pairs(rentals) do
        for other_area_ID, other_area_data in pairs(areas) do        
            -- compair the distance to center.
            local direction_difference = area_data.direction - other_area_data.direction
            area_rent.debug("Comparing selection to ".. other_area_data.name)
            if math.abs(direction_difference) < .5 or math.abs(direction_difference) > 5 then
                area_rent.debug("Direction difference between the two areas ".. math.abs(area_data.direction - other_area_data.direction))
                if math.abs(other_area_data.xz_center_distance - area_data.xz_center_distance) < area_rent.limit.w_max then
                    area_rent.debug(other_area_data.name.." is ".. math.abs(other_area_data.xz_center_distance - area_data.xz_center_distance) .." nodes from the selected area")
                    local centers_vector = vector.subtract(area_data.center,other_area_data.center)

                    if math.abs(centers_vector.y) <= area_data.dy/2 + other_area_data.dy/2 then
                        -- check the x and the z
                        area_rent.debug("The area heights are in the same plane ".. area_data.dy/2 + other_area_data.dy/2 .. "dy is greater then centers.y = "..math.abs(centers_vector.y).." ")
                        if math.abs(centers_vector.x) <= area_data.dx/2 + other_area_data.dx/2 and
                            math.abs(centers_vector.z) <= area_data.dz/2 + other_area_data.dz/2
                        then
                            area_rent.debug("There is an area conflict ")
                            area_rent.debug(area_data.dx/2 + other_area_data.dx/2 .. "dx  \t\tcenters.x = "..math.abs(centers_vector.x))
                            area_rent.debug(area_data.dz/2 + other_area_data.dz/2 .. "dz  \t\tcenters.z = "..math.abs(centers_vector.z))
                            intersecting_areas[other_area_ID] = other_area_data
                            if area_data.loaner ~= other_area_data.loaner then
                                return false
                            end
                        end
                    else
                        area_rent.debug("The area heights are not on the same plane ".. area_data.dy/2 + other_area_data.dy/2 .. "dy is less then centers.y = "..math.abs(centers_vector.y))
                    end
                else
                    area_rent.debug(other_area_data.name .. " is not within the radious of the selection")
                end     
            else
                area_rent.debug("But not within the direction window")
            end
            --area_rent.debug("Direction to ".. other_area_data.name .." is "..other_area_data.direction)
            --area_rent.debug("Distance to ".. other_area_data.name .." is "..other_area_data.distance_to_center)
        end
    end
    return intersecting_areas
end

function area_rent.xz_center(area_data,center)
    local pos1 = {x=area_data.pos1.x,y=0,z=area_data.pos1.z}
    local pos2 = {x=area_data.pos2.x,y=0,z=area_data.pos2.z}
    local pos3 = {x=center.x,y=0,z=center.z}

    area_data.xz_center = area_rent.center_pos(pos1,pos2)
    area_data.xz_center_distance = vector.distance(pos3, area_data.xz_center)

    return 0, 0
end