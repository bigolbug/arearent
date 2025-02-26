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
