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