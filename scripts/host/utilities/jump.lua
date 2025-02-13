local page = require("libs.TheKillerBunny.ActionWheelPlusPlus"):newPage("Jump", "minecraft:ender_pearl")
local num = page:newNumber("Block count", "minecraft:name_tag", function() end, 1, 12, 1)
local interval = 15

page:newButton("Lock Rotation", "minecraft:ender_eye", function()
   goofy:setRot(player:getRot():div(interval, interval):add(0.5, 0.5):floor():mul(interval, interval))
end)
page:newButton("Jump", "minecraft:nether_star", function()
   goofy:setPos(player:getPos() + player:getLookDir():normalize() * num:getValue())
end)
page:newNumber("Rotation lock interval", "minecraft:compass", function(num)
   interval = num
end, 1, 360, 15, 15, 60, 1)
page:newButton("Center on block", "minecraft:filled_map", function()
   goofy:setPos(player:getPos():floor():add(0.5, 0, 0.5))
end)

