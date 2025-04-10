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

function area_rent.Que_Area(pos1, pos2, requester, cost)
    local area_descriptor = area_rent.serialize(pos1, pos2, requester, cost)
    local area_name = requester .. "_".. os.time()
    
    --Check for stale areas
    local Qued_Areas = area_rent.areas_by_player(requester)

    --Add Record
    area_rent.metadata:set_string(area_name, area_descriptor)
    return area_name
end

function area_rent.serialize(pos1, pos2, requester, cost)
    return core.serialize(pos1) .. "," ..core.serialize(pos2).. "," .. requester .. "," .. cost .. ","..os.time()
end

function area_rent.deserialize(text)

    return pos1, pos2, requester, cost, time
end

function area_rent.area_count(player)
    local storage_table = area_rent.metadata:to_table()
    for key, value in pairs(storage_table["fields"]) do
        core.chat_send_all(key)
    end
end

function area_rent.areas_by_player(player)
    local storage_table = area_rent.metadata:to_table()
    local TBL = {}
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
    table.sort(areas) -- Checl to make sure that the tables are sorting correctly
    -- If there are 5 or more then update Meta data
    while #areas > area_rent.Queable_Area_Limit-1 do
        storage_table["fields"][areas[1]] = nil
        core.chat_send_all("Deleting ".. areas[1])
        TBL[areas[1]] = nil
        table.remove(areas,1)
        core.chat_send_all("The table now has entries: " .. #areas)
    end
    
    if area_rent.metadata:from_table(storage_table) then
        core.chat_send_all("\nSuccessful meta table write\n\n")
    else
        core.chat_send_all("\nFailed to write meta table\n\n")
    end
    return TBL
end

function area_rent:qualify(XP,cost)
    -- get all the properties of a player
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