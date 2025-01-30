local toggle = Wheel.toggles:newToggle("Fly", "minecraft:feather", function() end)
local forward = keybinds:fromVanilla("key.forward")
local scale = 1

local velocity = vectors.vec3()
function events.WORLD_TICK()
   if not toggle:isToggled() then
      return
   end
   if not player:isLoaded() then
      return
   end

   if forward:isPressed() then
      velocity = (player:getLookDir() * scale)
   else velocity = vec(0, 0, 0)
   end

   goofy:setVelocity(velocity)
end

forward:setOnPress(function()
   return toggle:isToggled()
end)

