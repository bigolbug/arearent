local indices = {}
local counts = {}
for _, area in pairs(areas.areas) do
    local i = indices[area.owner]
    --minetest.chat_send_all(_) -- This shows the index of the area in the areas array
    --minetest.chat_send_all(area.owner) -- This shows owner of the area in the areas array
    --minetest.chat_send_all(type(area))
    --minetest.chat_send_all("\n\n\n\n\n")

    for x in pairs(area) do
        minetest.chat_send_all(x)
    end

    minetest.chat_send_all("----------------------------------")
end
minetest.chat_send_all(".\n")

function area_rent.create_area(area_data)
    -- This is for updating the area mod
    local rental_data = core.deserialize(area_rent.metadata:get_string("RENTED"))
    local cued_data = core.deserialize(area_rent.metadata:get_string("CUED"))
    if not rental_data then
        rental_data = {}
    end

    if not rental_data[area_data.loaner] then
        rental_data[area_data.loaner] = {}
    end
    --table.insert(player_rental_data,core.serialize(area_data)) Use this if you don't need area ID's
    area_data.ID = areas:add(area_data.loaner, area_data.name, area_data.pos1, area_data.pos2, nil)
    areas:save()
    rental_data[area_data.loaner][area_data.name] = area_data
    cued_data[area_data.loaner][area_data.name] = nil
    area_rent.metadata:set_string("RENTED", core.serialize(rental_data))
    area_rent.metadata:set_string("CUED", core.serialize(cued_data))

    local last_day_charged = area_rent.metadata:get_int("last_charge_day")
    if last_day_charged == 0 then
        area_rent.metadata:set_int("last_charge_day",core.get_day_count)
        area_rent.debug("Initializing last_day_charge in Metadata")
    end

    return area_data.ID
end
