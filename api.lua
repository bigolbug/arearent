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
    area_rent.metadata:set_string(area_name, core.serialize(area_data))
    return area_name
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

    --Sort table, newest to oldest
    local areas = {}
    for area_name in pairs(TBL) do table.insert(areas, area_name) end
    table.sort(areas)
    -- If there are 5 or more then update Meta data
    while #areas > area_rent.cueable_Area_Limit and Status == "CUED" do
        storage_table["fields"][areas[1]] = nil
        --core.chat_send_all("Deleting ".. areas[1])
        TBL[areas[1]] = nil
        table.remove(areas,1)
        --core.chat_send_all("The table now has entries: " .. #areas)
    end
    
    area_rent.metadata:from_table(storage_table)

    return TBL
end

function area_rent.qualify(name,XP,cost,term)
    cost = cost or 0
    term = term or area_rent.qualifying_term
    -- get all the properties of a player
    local Total_Properties_Cost = cost
    for area_name, area_description in pairs(area_rent.areas_by_player(name,"RENTED")) do
        local area_data = core.deserialize(area_description)
        Total_Properties_Cost = Total_Properties_Cost + area_data.cost
    end

    if Total_Properties_Cost * term < XP then
        return true
    end
    return false
end

function area_rent.tableLen(TBL)
    local count = 0
    for key, value in pairs(TBL) do
        count = count + 1
    end
    return count
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
    local rental_data = area_rent.metadata:to_table()
    local current_time = os.time()
    if not rental_data["fields"]["last_charge_date"] then
        core.after(area_rent.scan_interval,area_rent.loop)
        core.chat_send_all("No previous rental")
        return false
    end
    local lapsed_time = current_time - rental_data["fields"]["last_charge_date"]

    local time_of_Day = core.get_timeofday()
    
    
    area_rent.metadata:from_table(rental_data)
    core.after(area_rent.scan_interval,area_rent.loop)
end

function area_rent.charge()
    local last_day_charged = area_rent.metadata:get_int("last_charge_day") or 0
    local current_day = core.get_day_count()
    if (math.abs(current_day - last_day_charged) == 0) and (area_rent.day_interval ~= 0) then
        return false
    end

    local area_data = area_rent.metadata:to_table()
    local renters = core.deserialize(area_data.fields.renters)
    -- parse through renteres list and charge each
    for _, renter in ipairs(renters) do
        local player_areas = area_rent.areas_by_player(renter,"rented")
        local XP = xp_redo.get_xp(renter)
        while not area_rent.qualify(renter,XP,0,2) do
            
        end

        if area_rent.tableLen(player_areas) then
            -- the player has active areas. 
            for area_ID, area_desciption in pairs(player_areas) do
                area_desciption = core.deserialize(area_desciption)
                xp_redo.add_xp(renter, -area_desciption.cost)
                if area_desciption.owner ~= "SERVER" then
                    xp_redo.add_xp(area_desciption.owner,area_desciption.cost)
                end
            end
        end
    end
    area_rent.metadata:from_table(area_data)
    area_rent.metadata:set_string("last_charge_date",os.time())
    area_rent.metadata:set_int("last_charge_day",core.get_day_count())
    return true
end

function area_rent.check_balance(name)
    local cued_Areas = area_rent.areas_by_player(name,"CUED")
    local Rented_Areas = area_rent.areas_by_player(name,"RENTED")
    local cued_table_Len = area_rent.tableLen(cued_Areas)
    local Rented_table_Len = area_rent.tableLen(Rented_Areas)
    --core.chat_send_all(Rented_table_Len)
    if Rented_table_Len > 0 then
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

    if cued_table_Len > 0 then
        message = message .. "\n\tYour cued areas are..."
        for Area_Name, Area_description in pairs(cued_Areas) do
            message = message .. "\n\t" .. Area_Name
        end
    else
        message = message .. "\n\tYou have no properties cued"
    end

    return false
end