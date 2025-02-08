local toggle = Wheel.toggles:newToggle("BetterFly", "minecraft:feather", function() end)
local forward = keybinds:fromVanilla("key.forward")
local backward = keybinds:fromVanilla("key.back")
local left = keybinds:fromVanilla("key.left")
local right = keybinds:fromVanilla("key.right")
local up = keybinds:fromVanilla("key.jump")
local down = keybinds:fromVanilla("key.sneak")
local speed = 1
Wheel.toggles:newNumber("BetterFly Speed", "minecraft:oak_boat", function(num)
   speed = num
end, 0, 9, 1, 1, 3, 0.1)

local velocity = vectors.vec3()
function events.WORLD_TICK()
   velocity = vectors.vec3()
   
   if not toggle:isToggled() then
      return
   end
   if not player:isLoaded() then
      return
   end

   if forward:isPressed() then
      velocity += player:getLookDir()
   end
   if backward:isPressed() then
      velocity += player:getLookDir() * -1
   end
   if left:isPressed() then
      velocity += vectors.rotateAroundAxis(90, player:getLookDir().x_z:normalize(), vec(0, 1, 0))
   end
   if right:isPressed() then
      velocity += vectors.rotateAroundAxis(-90, player:getLookDir().x_z:normalize(), vec(0, 1, 0))
   end
   if up:isPressed() then
      velocity += vec(0, 1, 0)
   end
   if down:isPressed() then
      velocity -= vec(0, 1, 0)
   end

   goofy:setVelocity(velocity:normalize() * speed)
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
   return toggle:isToggled()
end)
down:setOnPress(function()
   return toggle:isToggled()
end)

