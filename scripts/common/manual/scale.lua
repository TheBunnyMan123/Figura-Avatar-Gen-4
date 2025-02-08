local height = models.model.root.Head.HeightPivot:getPivot().y / 16
local eyeHeight = 1.62

local scaleUnitMultipliers = {
  none = 1/math.worldScale;
  m = (1/height);
  km = ((1/height) * 1000);
  cm = (1/height)/100;
  mm = (1/height)/1000;
  ["in"] = (0.0254/height);
  ft = ((0.0254*12)/height);
  px = ((0.0254/height)/96);
  pt = ((0.0254/height)/72);
  pc = (((0.0254/height)/96)*12);
  mcpx = ((1/height)/16);
}
local units = {}
for k in pairs(scaleUnitMultipliers) do
   table.insert(units, k)
end

local trustedServers = {
  ["plaza.figuramc.org"] = true,
  ["4p5.nz"] = true,
  ["nixos-server"] = true
}

local trueScale = 1.25 * (1/height)
local function setScale(scale)
   trueScale = scale

   if player:isLoaded() then
      avatar:store("patpat.boundingBox", player:getBoundingBox() * scale)
   end

   models.model.root:setScale(scale)
   nameplate.ENTITY:setScale(scale):setPivot(0, 2.25 * scale, 0)
end

nameplate.ENTITY:setScale(1):setPivot(0, 2.25, 0)
function pings.setScale(scale)
   setScale(scale)
end

local ActionWheel = require("libs.TheKillerBunny.ActionWheelPlusPlus")
local multiplier = 1/height
local scale = 1.25
ActionWheel:newRadio("Scale Unit", "minecraft:oak_sign", function(unit)
   multiplier = scaleUnitMultipliers[unit]
   pings.setScale(scale * multiplier * math.worldScale)
end, units, "m")
ActionWheel:newNumber("Scale", "minecraft:player_head", function(num)
   scale = num
   pings.setScale(scale * multiplier * math.worldScale)
end, 0, 15, 0.1, 1.25)

on["entity_init"] = function()
   setScale(1.25 * scaleUnitMultipliers.m)
end

local eyePos = 1.62
local oldEyePos = eyePos
on["tick"] = function()
   eyeHeight = player:getEyeHeight()
   local trustedServer = (not client.getServerData().ip) or (trustedServers[client.getServerData().ip]) or (player:getPermissionLevel() > 1)

   oldEyePos = eyePos
   eyePos = (eyeHeight * trueScale) - eyeHeight
   
   if not trustedServer then
      eyePos = 0
   end
end

on["render"] = function(delta)
   local lerped = math.lerp(oldEyePos, eyePos, delta)

   renderer:setOffsetCameraPivot(0, lerped, 0)
   renderer:setEyeOffset(0, lerped, 0)

   avatar:store("eyePos", vec(0, lerped, 0))
end

