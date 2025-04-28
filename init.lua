-- License: LGPLv2+

area_rent = {}

area_rent.modpath = minetest.get_modpath("area_rent")
dofile(area_rent.modpath.."/config.lua")
dofile(area_rent.modpath.."/api.lua")
dofile(area_rent.modpath.."/chatcommands.lua")
--dofile(area_rent.modpath.."/pos.lua")
--dofile(area_rent.modpath.."/hud.lua")

core.after(area_rent.scan_interval,area_rent.loop)
core.register_globalstep(function(dtime)
    --core.chat_send_all(dtime)
end)