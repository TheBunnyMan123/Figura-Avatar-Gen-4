local zoom = keybinds:of("Zoom", "key.keyboard.z")
local ActionWheel = require("libs.TheKillerBunny.ActionWheelPlusPlus")
local zoomLevel = (10/4)^(10/4)
ActionWheel:newNumber("Zoom Level", "minecraft:glass", function(num)
   num = num / 4
   zoomLevel = num^num
end, 1, 20, 1, 10)


on["WORLD_RENDER"] = function()
   if zoom:isPressed() then
      renderer:setFOV(1/zoomLevel)
   else
      renderer:setFOV()
   end
end

local cancel = false
on["mouse_move"] = function()
   cancel = not cancel
   return cancel and zoom:isPressed()
end

