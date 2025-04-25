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
function area_rent:admin(name,priv)
    if minetest.check_player_privs(name,priv) then
        return true
    end
    return false
end

function area_rent:splitter(params)

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
    local area_name = "CUED_".. area_data.loaner .. "_".. os.time()
    
    --Check for stale areas
    local cued_Areas = area_rent.areas_by_player(area_data.loaner, "CUED")

    --Add Record
    area_rent.metadata:set_string(area_name, core.serialize(area_data))
    return area_name
end

function area_rent.rent_area(area_data, renter)
    -- Who is renting from who?
    if area_data.loaner ~= renter then
        area_data.owner = area_data.loaner
        area_data.loaner = renter
    end
    local area_name = "RENTED_".. area_data.loaner .. "_".. os.time()
    local renter_list = core.deserialize(area_rent.metadata:get_string("renters"))
    table.insert(renter_list,renter)
    area_rent.metadata:set_string("renters",core.serialize(renter_list))
    --Add Record
    area_data.ID = area_rent.create_area(area_name,area_data)
    area_rent.metadata:set_string(area_name, core.serialize(area_data))
    
    return area_name
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
            area_desc = core.deserialize(area_desc)
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
            areas[i] = string.gsub (area_name,"^%d+%.","")
        end
    else
        --Sort table, newest to oldest
        for area_name, area_des in pairs(TBL) do table.insert(sort_areas, area_name) end
        table.sort(areas)
    end    


    return areas
end

function area_rent.areas_by_player(player, Status)
    
    local storage_table = area_rent.metadata:to_table()
    Status = string.upper(Status)
    local TBL = {}
    player = Status .. "_" .. player
    local name_len = string.len(player)
    for area_name, area_description in pairs(storage_table["fields"]) do
        --This next comment could be useful elsewhere. 
        --core.chat_send_all("comparing "..area_name.." with "..player)

        if string.sub(area_name,1,name_len) == player then
            TBL[area_name] = area_description
        end
    end

    if Status == "CUED" then
        local cued_areas = area_rent.sort(TBL)
        -- If there are 5 or more then update Meta data
        while #cued_areas > area_rent.cueable_Area_Limit do
            area_rent.metadata:set_string(cued_areas[1],nil)
            TBL[areas[1]] = nil
            table.remove(cued_areas,1)
        end    
    end
    
    return TBL
end

function area_rent.qualify(name,XP,cost,term)
    cost = cost or 0
    term = term or area_rent.qualifying_term
    -- get all the properties of a player
    local Total_Properties_Cost = cost
    local player_properties = area_rent.areas_by_player(name,"RENTED")
    
    --Count up the cost for all rentals
    if area_rent.tableLen(player_properties) then
        for area_name,area_data in pairs(player_properties) do
            area_data = core.deserialize(area_data)
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
        core.chat_send_all("something is wrong 6534")
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

function area_rent.loop()
    --Check to see when we charged last
    if not area_rent.metadata:get_int("last_charge_date") then
        core.after(area_rent.scan_interval,area_rent.loop)
        area_rent.debug("Area rent has no rentals to charge")
        return false
    end
    
    area_rent.charge()
    core.after(area_rent.scan_interval,area_rent.loop)
end

function area_rent.charge()
    local last_day_charged = area_rent.metadata:get_int("last_charge_day") or 0
    local current_day = core.get_day_count()
    if (math.abs(current_day - last_day_charged) == 0) and (area_rent.day_interval ~= 0) then
        return false
    end

    local renters = core.deserialize(area_rent.metadata:get_string("renters"))

    if not renters then
        core.log("error","Renters does not exist in meta data. Renters variable type: "..type(renters))
        return false
    end
    -- parse through renteres list and charge each
    for _, renter in ipairs(renters) do
        local player_areas = area_rent.areas_by_player(renter,"rented")
        local XP = xp_redo.get_xp(renter)

        --Check to make sure renter can make payment
        while (not area_rent.qualify(renter,XP,0,2)) and (area_rent.tableLen(player_areas)) do
            local removed,message = area_rent.remove_area(renter)
            if not removed then
                area_rent.debug("The removal function failed with this message: "..message)
                break
            end
            area_rent.remove_area(renter) -- Remove the smallest property and try again
            
        end

        -- Charge the player if they have properties
        if area_rent.tableLen(player_areas) then
            -- the player has active areas. 
            for area_name,area_desc in pairs(player_areas) do
                area_desc = core.deserialize(area_desc)
                xp_redo.add_xp(renter, -area_desc.cost)
                if area_desc.owner ~= "SERVER" then
                    xp_redo.add_xp(area_desc.owner,area_desc.cost)
                end
            end
        end
    end

    area_rent.metadata:set_int("last_charge_date",os.time())
    area_rent.metadata:set_int("last_charge_day",core.get_day_count())
    return true
end

function area_rent.check_balance(name)
    local cued_Areas = area_rent.areas_by_player(name,"CUED")
    local Rented_Areas = area_rent.areas_by_player(name,"RENTED")
    local message = ""

    --core.chat_send_all(Rented_table_Len)
    if area_rent.tableLen(Rented_Areas) then
        message = message .. "\n\tYour rented areas are..."
        local Total_cost = 0
        for Area_Name, Area_description in pairs(Rented_Areas) do
            local area_data = core.deserialize(Area_description)
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
        -- By default, find the smallest
        local player_areas = area_rent.areas_by_player(renter,"rented")
        player_areas = area_rent.sort(player_areas,"volume")
        if not player_areas then
            -- this player has no areas to remove. 
            return false, "no properties"
        end
        area_name = player_areas[1]
        
    end

    local area_data = core.deserialize(area_rent.metadata:get_string(area_name))
    
    ID = 3
    --ID = area_data.ID
    if not ID then
        -- ID Does not exist. 
        return false, "area_name"
    end

    ID = tonumber(ID)

    if not areas:isAreaOwner(ID, renter) then
        area_rent.debug("The Areas Mod does not agree that "..renter.." is the owner of area ID: "..ID)
        return false, "owner"
    end

    area_rent.metadata:set_string(area_name,nil)
    areas:remove(ID)
    areas:save()
    return true
end

function area_rent.create_area(area_name, area_data)
    core.chat_send_all("You need to finish the create area function")
    local ID = areas:add(area_data.loaner, area_name, area_data.pos1, area_data.pos2, nil)
	areas:save()
    return ID
end

function area_rent.debug(text)
    core.log(area_rent.debuglevel,text)
end