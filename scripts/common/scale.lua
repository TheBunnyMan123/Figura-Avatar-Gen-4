local height = models.model.root.Head.HeightPivot:getPivot().y / 16
local eyeHeight = 1.62

local scaleUnitMultipliers = {
  none = 1/math.worldScale;
  m = (1/height);
  km = ((1/height) * 1000);
  cm = (100/height);
  mm = (1000/height);
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
  ["4p5.nz"] = true
}

function pings.setScale(scale)
   if host:isHost() and player:isLoaded() then
      local trustedServer = (not client.getServerData().ip) or (trustedServers[client.getServerData().ip]) or (player:getPermissionLevel() > 1)
      renderer:setOffsetCameraPivot(0, (trustedServer and (eyeHeight * scale) - eyeHeight) or 0, 0)
      renderer:setEyeOffset(0, (trustedServer and (eyeHeight * scale) - eyeHeight) or 0, 0)
   end

   models.model.root:setScale(scale)
end

local ActionWheel = require("libs.TheKillerBunny.ActionWheelPlusPlus")
local multiplier = 1/math.worldScale
local scale = 1
ActionWheel:newRadio("Scale Unit", "minecraft:oak_sign", function(unit)
   multiplier = scaleUnitMultipliers[unit]
   pings.setScale(scale * multiplier * math.worldScale)
end, units, "none")
ActionWheel:newNumber("Scale", "minecraft:player_head", function(num)
   scale = num
   pings.setScale(scale * multiplier * math.worldScale)
end, 0, 15, 0.1, 1)

