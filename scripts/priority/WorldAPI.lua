local function pointOnPlane(point1, point2, checkPoint)
  minX = math.min(point1.x, point2.x)
  maxX = math.max(point1.x, point2.x)
  minY = math.min(point1.y, point2.y)
  maxY = math.max(point1.y, point2.y)
  minZ = math.min(point1.z, point2.z)
  maxZ = math.max(point1.z, point2.z)

  return checkPoint.x >= minX and checkPoint.x <= maxX and
    checkPoint.y >= minY and checkPoint.y <= maxY and
    checkPoint.z >= minZ and checkPoint.z <= maxZ
end

local sun_magic = 6.2831855 / 3 -- Taken straight from Minecraft's source. Thank you GrandpaScout
function figuraMetatables.WorldAPI.__index.getSunDir(delta)
  local frac = (world.getTimeOfDay(delta) / 24000 - 0.25) % 1
  return vectors.rotateAroundAxis(
    math.deg((frac * 2 + (0.5 - math.cos(frac * math.pi) * 0.5)) * sun_magic),
    vec(0, 1, 0),
    vec(0, 0, 1)
  )
end

figuraMetatables.WorldAPI.__index.lookingAtSun = function()
  local lookDir = player:getLookDir()
  local sunDir = world.getSunDir()

  local eyePos = player:getPos():add(0, player:getEyeHeight(), 0)
  local block, pos, side = raycast:block(eyePos, eyePos + player:getLookDir() * 10000, "VISUAL", "ANY")

  if not block:isTranslucent() then
    return false
  end

  return pointOnPlane(vec(-15, -15, -15), vec(15, 15, 15), ((sunDir - lookDir) * 180):floor())
end

