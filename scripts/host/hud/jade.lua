local function rotateBlockTaskCenterOffset(rot, pos)
  pos=pos-8
  pos = vectors.rotateAroundAxis(rot.x, pos, vec(1, 0, 0))
  pos = vectors.rotateAroundAxis(rot.y, pos, vec(0, 1, 0))
  pos = vectors.rotateAroundAxis(rot.z, pos, vec(0, 0, 1))
  return pos
end

local blockRot = vec(-33.4032, 39.8557, -22.9098)
local blockPos = rotateBlockTaskCenterOffset(blockRot, vec(27, 3.5, -10))

local hud = models:newPart("TKBunny$JadeHud", "HUD")
local text = hud:newText("text"):setPos(-3, 0, -10):setOutline(true)
local block = hud:newBlock("block"):setPos(blockPos):setRot(blockRot):setScale(0.9)
local entity = hud:newItem("entity"):setPos(11, -8.5, -10):setScale(1.2)
local lowerText = hud:newText("lowerText"):setPos(20.5, -21, -2):setOutline(true)

local bg = textures:newTexture("Jade$bg_center", 1, 1):setPixel(0, 0, vec(0.1, 0.1, 0.1, 0.7)):update()

---@type {[string]: SpriteTask}
local bground = hud:newSprite("bg_center"):setTexture(bg, 1, 1):setScale(1)

local function blockFunc(blockState)
   local id = blockState:getID()
   block:setBlock(blockState:toStateString())

   local json = {
      {
         translate = "block." .. id:match("^([a-z0-9_]-):") .. "." .. id:gsub("^[a-z0-9_]-:", ""),
         color = "white"
      },
      {
         text = "\n" .. blockState:getID(),
         color = "gray"
      }
   }

   local lowerJson = {}
   local iter = 1
   for property, value in pairs(blockState:getProperties()) do
      if iter > 1 then
         lowerJson[#lowerJson + 1] = {
            text = "\n"
         }
      end

      iter = iter + 1

      lowerJson[#lowerJson + 1] = {
         text = property:gsub("^.", string.upper):gsub("_", " "),
         color = "white"
      }
      lowerJson[#lowerJson + 1] = {
         text = ": ",
         color = "gray"
      }

      local color = "yellow"
      if value == "true" or value == "false" then
         color = "light_purple"
      elseif value:match("^[0-9]$") then
         color = "aqua"
      end

      lowerJson[#lowerJson + 1] = {
         text = value,
         color = color
      }
   end

   text:setText(toJson(json))

   local jsonSize, lowerJsonSize = client.getTextDimensions(toJson(json)), client.getTextDimensions(toJson(lowerJson))

   local min = vec(18, 2, 0)
   local max = vectors.vec3()--client.getTextDimensions(toJson(json)).xy_:mul(-1, -1, -1) + (toJson(lowerJson) ~= "{}" and client.getTextDimensions(toJson(lowerJson))._y_:add(0, 5, 0):mul(-1, -1, -1) or 0)
   max.x = math.max(jsonSize.x, lowerJsonSize.x - min.x - 5)
   max.y = jsonSize.y + (lowerJson[1] and lowerJsonSize.y + 2 or 0)
   max = max * -1

   if toJson(lowerJson) ~= "{}" then
      lowerText:setText(toJson(lowerJson))
   end
   bground:setSize(max.xy - min.xy - vec(12, 4)):setVisible(true):setPos(max.xy_ - vec(6, 2, 0))
   hud:setPos((client.getScaledWindowSize().x + (max.x - min.x + 36)) / -2, -10, -9000)
end

local function entityFunc(targetedEntity)
   if not targetedEntity then return end
   local id = targetedEntity:getType()
   local succ = pcall(entity.setItem, entity, id .. "_spawn_egg")
   entity:setVisible(succ)

   local json = {
      {
         translate = "entity." .. id:match("^([a-z0-9_]-):") .. "." .. id:gsub("^[a-z0-9_]-:", ""),
         color = "white"
      },
      {
         text = "\n" .. id,
         color = "gray"
      }
   }

   local lowerJson = {}

   if id == "minecraft:item" then
      entity:setVisible(true):setItem(targetedEntity:getNbt().Item.id)
      lowerJson[#lowerJson + 1] = {
         text = "Count",
         color = "white"
      }
      lowerJson[#lowerJson + 1] = {
         text = ": ",
         color = "gray"
      }
      lowerJson[#lowerJson + 1] = {
         text = tostring(targetedEntity:getNbt().Item.count),
         color = "aqua"
      }

      lowerJson[#lowerJson + 1] = {
         text = "\nItem",
         color = "white"
      }
      lowerJson[#lowerJson + 1] = {
         text = ": ",
         color = "gray"
      }
      lowerJson[#lowerJson + 1] = {
         text = tostring(targetedEntity:getNbt().Item.id),
         color = "yellow"
      }
   end

   text:setText(toJson(json))
   
   local jsonSize, lowerJsonSize = client.getTextDimensions(toJson(json)), client.getTextDimensions(toJson(lowerJson))

   local min = vec(18, 2, 0)
   local max = vectors.vec3()--client.getTextDimensions(toJson(json)).xy_:mul(-1, -1, -1) + (toJson(lowerJson) ~= "{}" and client.getTextDimensions(toJson(lowerJson))._y_:add(0, 5, 0):mul(-1, -1, -1) or 0)
   max.x = math.max(jsonSize.x, lowerJsonSize.x - min.x - 5)
   max.y = jsonSize.y + (lowerJson[1] and lowerJsonSize.y + 2 or 0)
   max = max * -1

   if toJson(lowerJson) ~= "{}" then
      lowerText:setText(toJson(lowerJson))
   end
   bground:setSize(max.xy - min.xy - vec(12, 4)):setVisible(true):setPos(max.xy_ - vec(6, 2, 0))
   hud:setPos((client.getScaledWindowSize().x + (max.x - min.x + 36)) / -2, -10, -9000)
end

on["tick"] = function()
   bground:setVisible(false)

   text:setText("")
   lowerText:setText("")
   block:setBlock("minecraft:air")
   entity:setVisible(false)

   local blockState = player:getTargetedBlock(true, host:getReachDistance())
   local targetedEntity = player:getTargetedEntity(host:getReachDistance())

   local entityLen, blockLen
   if not targetedEntity then
      entityLen = math.huge
      blockLen = 0
   else
      entityLen = (targetedEntity:getPos() - player:getPos()):length()
      blockLen = (blockState:getPos() - player:getPos()):length()
   end

   if blockState:isAir() and not entity then return end
   if (blockState:isAir() or entityLen < blockLen) and entity then
      entityFunc(targetedEntity)
   else
      blockFunc(blockState)
   end
end

