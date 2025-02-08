local gravity = 9.8 / 20
local toggle = Wheel.toggles:newToggle("Weird Movement", "minecraft:player_head", function() end)
local forward = keybinds:fromVanilla("key.forward")
local backward = keybinds:fromVanilla("key.back")
local left = keybinds:fromVanilla("key.left")
local right = keybinds:fromVanilla("key.right")
local up = keybinds:fromVanilla("key.jump")
local down = keybinds:fromVanilla("key.sneak")

local velocity = vectors.vec3()
function events.WORLD_TICK()
   if not player:isLoaded() then return end
   velocity = player:getVelocity() * 0.98
   velocity = velocity - vec(0, gravity, 0)

   if player:isOnGround() then
      velocity = velocity * 0.25
   end

   if not toggle:isToggled() then
      return
   end
   if not player:isLoaded() then
      return
   end

   if forward:isPressed() then
      velocity = velocity + player:getLookDir().x_z:normalize()
   end
   if backward:isPressed() then
      velocity = velocity - player:getLookDir().x_z:normalize()
   end
   if left:isPressed() then
      velocity = velocity + vectors.rotateAroundAxis(90, player:getLookDir().x_z:normalize(), vec(0, 1, 0))
   end
   if right:isPressed() then
      velocity = velocity + vectors.rotateAroundAxis(-90, player:getLookDir().x_z:normalize(), vec(0, 1, 0))
   end

   goofy:setVelocity(velocity)
end

forward:setOnPress(function()
   return toggle:isToggled()
end)
backward:setOnPress(function()
   return toggle:isToggled()
end)
left:setOnPress(function()
   return toggle:isToggled()
end)
right:setOnPress(function()
   return toggle:isToggled()
end)
up:setOnPress(function()
   if toggle:isToggled() then
      goofy:setVelocity(player:getVelocity() + vec(0, 5, 0))
   end
   return toggle:isToggled()
end)
down:setOnPress(function()
   return toggle:isToggled()
end)

