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
    --local last_charge_time = area_rent.metadata:get_int("last_charge_time")
    local last_scan = area_rent.metadata:get_int("last_scan")
    local current_day = core.get_day_count()
    local current_time = os.time()
    --area_rent.debug("current day count "..current_day..". Last charge date ".. last_day_charged)
    if math.abs(current_day - last_day_charged) ~= 0 or area_rent.day_interval == 0 then
        --It is a new day but should we scan?
        if current_time - last_scan > area_rent.scan_interval then
            area_rent.debug("Charging players")
            area_rent.charge()    
            area_rent.metadata:set_int("last_scan",current_time)
            return
        end
        if math.abs(current_time - last_scan) > 100000 then
            area_rent.metadata:set_int("last_scan",current_time)
            area_rent.debug("Something is going on with os.time()")
            return
        end
    end

    -- Sync XP_redo with area_rent
    if current_time - last_scan > area_rent.scan_interval then
        area_rent.debug("Syncing XP")
        local rental_data = core.deserialize(area_rent.metadata:get_string("RENTED"))
        if rental_data then
            for renter, value in pairs(rental_data) do
                area_rent.updateXP(renter)
                area_rent.debug("Syncing XP for ".. renter)
            end
        end
        
        area_rent.metadata:set_int("last_scan",current_time)
    end
    --core.chat_send_all(dtime)
end)

core.register_on_joinplayer(function(player)
    local renter = player:get_player_name()
    local old_XP = xp_redo.get_xp(renter) or 0
    local current_XP = area_rent.metadata:get_int(renter.."XP")
    area_rent.debug(renter.. " just joined the game, let's setup a few things")
    if current_XP == 0 then
        -- This is a new player. Creating entry in metadata
        area_rent.metadata:set_int(renter.."XP",old_XP)
    else
        -- This is a returning player. Update XP
        local discrepancy = current_XP - old_XP
        xp_redo.add_xp(renter, discrepancy)
        area_rent.debug("Updating "..renter.. "'s xp_redo data. "..
        "\nxp_redo had ".. old_XP .. " but while offline their XP changed to "..current_XP)
    end

    --Setup the rental data for user
    local rental_data = core.deserialize(area_rent.metadata:get_string("RENTED"))
    if rental_data then
        if not rental_data[renter] then
            area_rent.debug("Adding ".. renter .. " to RENTED metadata")
            rental_data[renter] = {}
            area_rent.metadata:set_string("RENTED", core.serialize(rental_data))
        end
    end
end)
