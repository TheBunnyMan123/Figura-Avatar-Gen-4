local toggle = Wheel.toggles:newToggle("Weird velocity movement or smthn", "minecraft:feather", function() end)
local forward = keybinds:fromVanilla("key.forward")

local velocity = vectors.vec3()
function events.WORLD_TICK()
   if not toggle:isToggled() then
      return
   end
   if not player:isLoaded() then
      return
   end

   if forward:isPressed() then
      velocity = velocity + (player:getLookDir() / 20)
   end

   goofy:setVelocity(velocity)
end

forward:setOnPress(function()
   return toggle:isToggled()
end)

