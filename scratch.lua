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