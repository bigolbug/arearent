-- License: LGPLv2+

area_rent = {}

area_rent.modpath = minetest.get_modpath("area_rent")
dofile(area_rent.modpath.."/config.lua")
dofile(area_rent.modpath.."/api.lua")
dofile(area_rent.modpath.."/chatcommands.lua")
--dofile(area_rent.modpath.."/pos.lua")
--dofile(area_rent.modpath.."/hud.lua")

core.register_globalstep(function(dtime)
    local last_day_charged = area_rent.metadata:get_int("last_charge_day")
    if last_day_charged == 0 then
        last_day_charged = core.get_day_count()
    end
    local last_charge_time = area_rent.metadata:get_int("last_charge_time")
    local last_scan = area_rent.metadata:get_int("last_scan")
    local current_day = core.get_day_count()
    if (math.abs(current_day - last_day_charged) == 0) and (area_rent.day_interval ~= 0) then
        -- No need to charge since it is not a new day. 
        return false
    else
        --It is a new day but should we scan?
        if os.time() - last_scan > area_rent.scan_interval then
            area_rent.charge()    
            area_rent.metadata:set_int("last_scan",os.time())
        end
        if math.abs(os.time() - last_scan) > 100000 then
            area_rent.metadata:set_int("last_scan",os.time())
            area_rent.debug("Something is going on with os.time()")
        end
    end
    --core.chat_send_all(dtime)
end)

core.register_on_joinplayer(function(player)
    local renter = player:get_player_name()
    local old_XP = xp_redo.get_xp(renter) or 0
    local current_XP = area_rent.metadata:get_int(renter.."XP")
    
    if current_XP == 0 then
        -- This is a new player. Creating entry in metadata
        area_rent.metadata:set_int(renter.."XP",old_XP)
    else
        -- This is a returning player. Update XP
        local discrepancy = current_XP - old_XP
        xp_redo.add_xp(renter, discrepancy)
    end
end)
