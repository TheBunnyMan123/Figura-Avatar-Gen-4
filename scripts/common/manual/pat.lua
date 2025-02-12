local BunnyParticles = require("libs.TheKillerBunny.BunnyParticles")

local infinipat = true
local range = 1000
local patting = false
local right = keybinds:of("Right click", "key.mouse.right")
local particle = BunnyParticles.newParticle({
   textures:fromVanilla("goldheart_2", "minecraft:textures/particle/goldheart_2.png"),
   textures:fromVanilla("goldheart_1", "minecraft:textures/particle/goldheart_1.png"),
   textures:fromVanilla("goldheart_0", "minecraft:textures/particle/goldheart_0.png")
}, 25, vec(0, 3, 0), 0.85)

avatar:store("patpat.yesPats", true)
local function onPat(uuid)
end

function pings.setInfinipat(state)
   infinipat = state
end

require("libs.TheKillerBunny.ActionWheelPlusPlus"):newToggle("infinipat", "minecraft:wolf_spawn_egg", function(state)
   pings.setInfinipat(state)
end):setToggled(true)


local function cleanse(vector)
   if not vector then return end

   return figuraMetatables.Vector3.__index(vector, "xyz")
end

local function getVarsFromHead(block)
   if block.id == "minecraft:player_head" or block.id == "minecraft:player_wall_head" then
      local entityData = block:getEntityData()
      if entityData then
         local skullOwner = entityData.SkullOwner and entityData.SkullOwner.Id and client.intUUIDToString(table.unpack(entityData.SkullOwner.Id))
         if skullOwner then
            return world.avatarVars()[skullOwner] or {}
         end
      end
   end
end

local function getTargetedEntity()
   local start = player:getPos():add(0, player:getEyeHeight()):add(renderer:getEyeOffset())
   local entity = raycast:entity(start, start + (player:getLookDir() * range), function(entity) return entity ~= player end)

   if not entity then
      local pPos = player:getPos()
      local aabbs = {}
      local aabbMap = {}

      for _, v in pairs(world.getEntities(pPos - range, pPos + range)) do
         local box = v:getVariable("patpat.boundingBox")
         local pos = v:getPos()
         
         if v == player then goto continue end
         if not box then goto continue end

         local halfBox = box / 2
         local aabb = {
            pos - halfBox.x_z,
            pos + halfBox:mul(1, 2, 1)
         }

         aabbs[#aabbs + 1] = aabb
         aabbMap[aabb] = v

         ::continue::
      end

      local hit = raycast:aabb(start, start + (player:getLookDir() * range), aabbs)
      if hit then
         return aabbMap[hit]
      end
   end

   return entity
end

local function getTargetedBlock()
   local start = player:getPos():add(0, player:getEyeHeight()):add(renderer:getEyeOffset())

   return raycast:block(start, start + (player:getLookDir() * range))
end

local function isBlockValid(block)
   if block:isAir() then
      return false
   end

   local id = block:getID()
   if not id:match("head") and not id:match("skull") then
      return false
   end

   return true
end

local function getPatTarget()
   local entity = getTargetedEntity()
   local block = getTargetedBlock()

   if not entity then
      if not isBlockValid(block) then
         return
      end

      return block
   elseif not block then
      return entity
   end

   local pos = player:getPos()
   local ePos = entity:getPos()
   local bPos = block:getPos()

   if (pos - bPos):length() < (pos - ePos):length() then
      if not isBlockValid(block) then
         return
      end

      return block
   else
      return entity
   end
end

local function randomVec(val)
   return vec(
      (math.random() * 2 - 1) * val.x,
      math.random() * val.y,
      (math.random() * 2 - 1) * val.z
   )
end

local function pattingEntityAllowed(entity)
   return entity:getVariable("patpat.yesPats") ~= false and not entity:getVariable("patpat.noPats")
end


local function pat(target)
   if not player:isLoaded() then return end
   host:swingArm()

   local targetInfo
   if type(target) == "string" then
      target = world.getEntity(target)
      if not target then return end

      local targetPetpetFunc = target:getVariable("petpet")
      noHearts = target:getVariable("patpat.noHearts")
      targetInfo = {
         pos = target:getPos(),
         box = cleanse(target:getVariable("patpat.boundingBox")) or target:getBoundingBox()
      }

      if targetPetpetFunc then
         pcall(targetPetpetFunc, avatar:getUUID(), 3)
      end
      if target:getVariable("patpat.noHearts") then return end
   elseif type(target) == "Vector3" then
      target = world.getBlockState(cleanse(target))
      if not target then return end

      targetInfo = {
         pos = target:getPos() + vec(0.5, 0, 0.5),
         box = vec(0.7, 0.7, 0.7)
      }

      local vars = getVarsFromHead(target)

      if vars then
         pcall(vars["petpet.playerHead"], avatar:getUUID(), 2, targetInfo.pos:unpack())
         if vars["patpat.noHearts"] then return end
      end
   end

   local halfBox = targetInfo.box / 2
   local particleHalfBox = targetInfo.box - halfBox.x_z

   local playerHeartPos = player:getVariable("patpat.boundingBox").y / 2
   local playerHeartVec = vec(0, playerHeartPos, 0) + player:getPos()

   particle:setPos(targetInfo.pos + randomVec(particleHalfBox)):setVelocity(vec(0, 3, 0) * ((math.random() / 5) + 0.9)):spawn()
   particle:setPos(playerHeartVec):setVelocity((targetInfo.pos + halfBox:copy():mul(0, 1.25, 0) - playerHeartVec) * 2.35):spawn()
end

---@diagnostic disable-next-line unused-variable
local petpetFunc = function(uuid, timer)
   onPat(uuid)
end


function pings.stopPatting()
   patting = false
end

function pings.startPatting(uuid1, uuid2, uuid3, uuid4)
   patting = {uuid1, uuid2, uuid3, uuid4}
end


on["render"] = function()
   if not patting then return end
   if not infinipat then return end

   local uuid1, uuid2, uuid3, uuid4 = table.unpack(patting)

   if type(uuid1) == "number" then
      pat(client.intUUIDToString(uuid1, uuid2, uuid3, uuid4))
   else
      pat(uuid1)
   end
end

local bad = 0
local lastPat = 0
local oldTarget
on["tick"] = function(tick)
   if not right:isPressed() or not player:isSneaking() or player:getHeldItem():getCount() ~= 0 then
      if patting then
         pings.stopPatting()
      end

      if host:isHost() then
         return
      end
   end
   if not host:isHost() and not player:isSneaking() then
      bad = bad + 1

      if bad >= 60 then
         patting = false
      end
   else
      bad = 0
   end

   if tick % 30 == 0 then
      pings.setInfinipat(infinipat)
   end

   if not infinipat and patting then
      if (lastPat + 2) < tick then
         lastPat = tick

         local uuid1, uuid2, uuid3, uuid4 = table.unpack(patting)

         if type(uuid1) == "number" then
            pat(client.intUUIDToString(uuid1, uuid2, uuid3, uuid4))
         else
            pat(uuid1)
         end
      end
   end

   if host:isHost() then
      local target = getPatTarget() --[[@as BlockState|Entity]]

      if not patting and type(target) == "BlockState" then
         pings.startPatting(target:getPos():floor())
         oldTarget = target
      elseif not patting and target and type(target) ~= "BlockState" and pattingEntityAllowed(target) then
         pings.startPatting(client.uuidToIntArray(target:getUUID()))
         oldTarget = target
      elseif patting and target and oldTarget ~= target then
         patting = false -- Cause a recheck on only the host
      elseif not target and patting then
         pings.stopPatting()
      end
   end
end

avatar:store("petpet", petpetFunc)

