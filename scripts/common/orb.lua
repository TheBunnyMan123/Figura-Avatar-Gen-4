local orbPos = vectors.vec3()
local toggled = false

function pings.toggleOrb(state, x, y, z)
   toggled = state
   orbPos = vec(x, y, z) + 0.5
end

Wheel.toggles:newToggle("Orb", "minecraft:magma_cream", function(state)
   local pos = player:getPos():floor()

   pings.toggleOrb(state, pos.x, pos.y + 3, pos.z)
end)

local function rand()
   return (math.random() * 2) - 1
end

local goodBlocks = {}

for _, block in pairs(client.getRegistry("minecraft:block")) do
   local succ, state = pcall(world.newBlock, block, 0, 0, 0)

   if succ and state:isSolidBlock() and not state:isTranslucent() then
      table.insert(goodBlocks, block)
   end
end

function events.TICK()
   if toggled then
      for _, block in pairs(goodBlocks) do
         local dir = vec(rand(), rand(), rand()):normalize() * 2

         particles:newParticle('minecraft:block ' .. block, orbPos + dir, 0, 0, 0):setVelocity(-dir / 16):setGravity(0):setLifetime(16)
      end
   end
end

