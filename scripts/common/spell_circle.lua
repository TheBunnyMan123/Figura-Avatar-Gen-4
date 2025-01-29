local circle = models.spell_circle.circle

---@param part ModelPart
---@return Matrix4
local function getMatrix(part)
   if part:getParent() then
      return part:getPositionMatrix() + getMatrix(part:getParent())
   end

   return part:getPositionMatrix()
end

local invertColors = function(color, x, y)
   local r, g, b, a = color:unpack()

   return vec((r * -1) + 1, (g * -1) + 1, (b * -1) + 1, a)
end

local emissiveStar = textures:newTexture("spell_circle.emissive_star", 128, 128)
local emissiveText = textures:newTexture("spell_circle.emissive_text", 128, 128)
local emissiveStill = textures:newTexture("spell_circle.emissive_still", 128, 128)

textures["textures.spell_circle_star"]:applyFunc(0, 0, 128, 128, invertColors):update():applyFunc(0, 0, 128, 128, function(col, x, y)
   emissiveStar:setPixel(x, y, col.w, col.w, col.w, col.w)

   return col
end)
textures["textures.spell_circle_text"]:applyFunc(0, 0, 128, 128, invertColors):update():applyFunc(0, 0, 128, 128, function(col, x, y)
   emissiveText:setPixel(x, y, col.w, col.w, col.w, col.w)

   return col
end)
textures["textures.spell_circle_still"]:applyFunc(0, 0, 128, 128, invertColors):update():applyFunc(0, 0, 128, 128, function(col, x, y)
   emissiveStill:setPixel(x, y, col.w, col.w, col.w, col.w)

   return col
end)

circle.still:setSecondaryTexture("CUSTOM", emissiveStill):setSecondaryRenderType("EMISSIVE")
circle.clockwise:setSecondaryTexture("CUSTOM", emissiveText):setSecondaryRenderType("EMISSIVE")
circle.counterclockwise:setSecondaryTexture("CUSTOM", emissiveStar):setSecondaryRenderType("EMISSIVE")


local tick = 0
on["tick"] = function()
   tick = tick + 1
end

local hand = models.model.root.RightArm.HandPivot
local mode = "none"

on["render"] = function(delta, _, matrix)
   if mode ~= "none" then
      local rot = math.lerpAngle((tick - 1) * 2, tick * 2, delta)
      
      if mode == "arm" then
         rot = rot * -1
         circle.still:setOffsetRot(180, 180)
         circle.clockwise:setOffsetRot(180, 180)
         circle.counterclockwise:setOffsetRot(180, 180)
      else
         circle.still:setOffsetRot()
         circle.clockwise:setOffsetRot()
         circle.counterclockwise:setOffsetRot()
      end

      circle.clockwise:setRot(0, -rot)
      circle.counterclockwise:setRot(0, rot)
      circle:setOffsetPivot():setRot():setPos():setScale()
   end

   if mode == "none" then
      circle:setVisible(false)
   elseif mode == "belowPlayer" then
      circle:setParentType("WORLD"):setVisible(true):setPos(player:getPos(delta) * 16 + vec(0, 0.1, 0)):setScale(10)
   elseif mode == "arm" then
      circle:setVisible(true):setParentType("RIGHT_ARM"):setOffsetPivot(-2, 10.2, 0):setPos(6, 11.8)
   end

end

function pings.setCircleMode(newMode)
   if newMode == 1 then
      mode = "none"
   elseif newMode == 2 then
      mode = "belowPlayer"
   elseif newMode == 3 then
      mode = "arm"
   end
end

function pings.setSpellColor(col)
   for _, v in pairs(circle:getChildren()) do
      v:setColor(col)
   end
end

function pings.setSpellEmissive(state)
   for _, v in pairs(circle:getChildren()) do
      v:setSecondaryRenderType(state and "EMISSIVE" or "NONE")
   end
end

local ActionWheel = require("libs.TheKillerBunny.ActionWheelPlusPlus"):newPage("Spell Circle", "minecraft:dragon_breath")
ActionWheel:newRadio("Spell Circle Mode", "minecraft:snowball", function(newMode)
   if newMode == "none" then
      pings.setCircleMode(1)
   elseif newMode == "below player" then
      pings.setCircleMode(2)
   elseif newMode == "arm" then
      pings.setCircleMode(3)
   end
end, {"none","below player", "arm"})
ActionWheel:newColor("Spell Circle Color", "minecraft:magma_cream", function(col)
   pings.setSpellColor(col)
end, vec(1, 1, 1))
ActionWheel:newToggle("Emissive spell circle", "minecraft:redstone_lamp", function(state)
   pings.setSpellEmissive(state)
end):setToggled(true)

