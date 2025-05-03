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

function area_rent.get_area_by_name(search_name,owner)
    local cued_Areas = core.deserialize(area_rent.metadata:get_string("CUED"))
    local rented_Areas = core.deserialize(area_rent.metadata:get_string("RENTED"))
    local TBL = {}
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

function area_rent.rent_area(area_data, renter)
    -- Who is renting from who?
    if area_data.loaner ~= renter then
        area_data.owner = area_data.loaner
        area_data.loaner = renter
    end
    
    local renter_list = core.deserialize(area_rent.metadata:get_string("RENTERS"))
    if not renter_list then
        renter_list = {}
    end
    
    if not renter_list[renter] then
        renter_list[renter] = {}
    end
    renter_list[renter][area_data.time]=area_data
    area_rent.metadata:set_string("RENTERS",core.serialize(renter_list))
    --Add Record
    area_rent.create_area(area_data)
    
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

function area_rent.qualify(name,XP,cost,term)
    cost = cost or 0
    term = term or area_rent.qualifying_term
    -- get all the properties of a player
    local Total_Properties_Cost = cost
    local player_properties = area_rent.get_areas_by_player(name,"RENTED")
    
    --Count up the cost for all rentals
    if area_rent.tableLen(player_properties) then
        for area_name,area_data in pairs(player_properties) do
            Total_Properties_Cost = Total_Properties_Cost + area_data.cost
        end
    end

    -- If the daily property cost is less then the players XP return true
    if Total_Properties_Cost * term < XP then
        return true
    end

    return false
end

function area_rent.tableLen(TBL)
    local count = 0

    if not TBL then
        area_rent.debug("The table was not defined in the tableLen function")
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

        local XP = area_rent.metadata:get_int(renter.."XP")
        local player_areas = area_rent.get_areas_by_player(renter,"rented")
        

        --Check to make sure renter can make payment
        while (not area_rent.qualify(renter,XP,0,2)) and (area_rent.tableLen(player_areas)) do
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
    local area_data = area_rent.get_area_by_name(area_name)
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
    rented_areas.renter.area_name = nil
    area_rent.metadata:set_string(area_name,"")
    areas:remove(ID)
    areas:save()
    return true
end

function area_rent.create_area(area_data)
    local rental_data = core.deserialize(area_rent.metadata:get_string("RENTED"))
    if not rental_data then
        rental_data = {}
    end
    local player_rental_data = rental_data[area_data.loaner]
    if not player_rental_data then
        rental_data[area_data.loaner] = {}
    end
    --table.insert(player_rental_data,core.serialize(area_data)) Use this if you don't need area ID's
    area_data.ID = areas:add(area_data.loaner, area_data.name, area_data.pos1, area_data.pos2, nil)
    areas:save()
    rental_data[area_data.loaner][area_data.name] = area_data
    area_rent.metadata:set_string("RENTED", core.serialize(rental_data))
    return area_data.ID
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

    if core.get_player_by_name(player) then
        --Online
        local prev_XP = xp_redo.get_xp(player)
        local new_XP = prev_XP + XP
        xp_redo.add_xp(player,XP)
        area_rent.metadata:set_int(player.."XP",new_XP) 

    else
        --offline
        local prev_XP = area_rent.metadata:get_int(player.."XP")
        local new_XP = prev_XP + XP

        if new_XP < 0 then
            area_rent.metadata:set_int(player.."XP",0) 
            area_rent.debug(player.. " has negative XP for their new_XP: "..new_XP)
        else
            area_rent.metadata:set_int(player.."XP",new_XP) 
        end    
    end
    return true
end