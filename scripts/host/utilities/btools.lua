local async = require("libs.TheKillerBunny.BunnyAsync")
local BunnyLineLib = require("libs.TheKillerBunny.BunnyLineLib")
local page = require("libs.TheKillerBunny.ActionWheelPlusPlus"):newPage("Build Tools", "minecraft:iron_axe")
local click = keybinds:fromVanilla("key.attack")

local function getMinMax(pos1, pos2)
  local min = vec(math.min(pos1.x, pos2.x), math.min(pos1.y, pos2.y), math.min(pos1.z, pos2.z))
  local max = vec(math.max(pos1.x, pos2.x), math.max(pos1.y, pos2.y), math.max(pos1.z, pos2.z))

  return min, max
end

local function set(pos, block)
   host:sendChatCommand(("setblock %i %i %i "):format(pos:unpack()) .. block)
end

local function sphere(pos, rad, block)
   async.for_(pos.x - rad, pos.x + rad, 1, function(x)
      async.for_(pos.y - rad, pos.y + rad, 1, function(y)
         async.for_(pos.z - rad, pos.z + rad, 1, function(z)
            local point = vec(x, y, z)
            if (point - pos):length() > rad then
               return
            end

            set(point, block)
         end)
      end)
   end)
end

local function fill(pos1, pos2, block)
   pos1, pos2 = getMinMax(pos1, pos2)
   local SIDE_SIZE = 8

   async.for_(pos1.x, pos2.x, SIDE_SIZE, function(x)
      async.for_(pos1.y, pos2.y, SIDE_SIZE, function(y)
         async.for_(pos1.z, pos2.z, SIDE_SIZE, function(z)
            local ex = math.min(x + SIDE_SIZE - 1, pos2.x)
            local ey = math.min(y + SIDE_SIZE - 1, pos2.y)
            local ez = math.min(z + SIDE_SIZE - 1, pos2.z)

            host:sendChatCommand("fill " ..
               x .. " " .. y .. " " .. z .. " " ..
               ex .. " " .. ey .. " " .. ez .. " " .. block
            )
         end)
      end)
   end)
end

local function twoPosFunction(func)
   local clicking = true
   local tick = 0
   local pos1
   local pos2

   local registered
   registered = function()
      tick = tick + 1
      if not pos1 and not clicking then
         if click:isPressed() then
            pos1 = player:getTargetedBlock(true, 20):getPos()
            clicking = true
         end
      elseif pos1 and not pos2 then
         local targeted = player:getTargetedBlock(true, 20):getPos()
         if click:isPressed() and not clicking then
            pos2 = targeted
            clicking = true
         end
         local min, max = getMinMax(pos1, targeted)
         max:add(1, 1, 1)
         if tick % 5 == 0 then
            BunnyLineLib.box(min, max, 12)
         end
      elseif pos1 and pos2 then
         func(getMinMax(pos1, pos2))
         events.WORLD_TICK:remove(registered)
      end

      if not click:isPressed() then
         clicking = false
      end
   end

   events.WORLD_TICK:register(registered)
end

local block = "minecraft:glass"
page:newText("Block", "minecraft:grass_block", function(s)
   block = s
end, "minecraft:glass")

local radius = page:newNumber("Sphere radius", "minecraft:slime_ball", function() end, 0, 64, 4)
page:newButton("Generate sphere", "minecraft:magma_cream", function()
   sphere(player:getPos(), radius:getValue(), block)
end)

page:newButton("Fill", "minecraft:structure_block", function()
   twoPosFunction(function(pos1, pos2)
      fill(pos1, pos2, block)
   end)
end)

page:newButton("Ellipsoid", "minecraft:diamond", function()
   twoPosFunction(function(pos1, pos2)
      pos1 = pos1 - 1
      pos2 = pos2 + 1

      local delta = pos2 - pos1
      local center = pos1 + (delta / 2)
      local radius = (pos2 - pos1) / 2

      async.for_(pos1.x, pos2.x, 1, function(x)
         async.for_(pos1.y, pos2.y, 1, function(y)
            async.for_(pos1.z, pos2.z, 1, function(z)
               local squaredDistance = (x - center.x)^2 / radius.x^2 +
                  (y - center.y)^2 / radius.y^2 +
                  (z - center.z)^2 / radius.z^2
               
               if squaredDistance < 1 then
                  set(vec(x, y, z), block)
               end
            end)
         end)
      end)
   end)
end)

