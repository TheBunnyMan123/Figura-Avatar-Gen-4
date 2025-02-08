local eyes = models.model.root.Head.Eyes
local BLINK_RATE = 4 * 20

eyes:setSecondaryRenderType("EMISSIVE_SOLID")

local oldScale = vec(1, 1, 1)
local newScale = vec(1, 1, 1)
local oldPos = vec(0, 0, 0)
local newPos = vec(0, 0, 0)

local tick = 0
function events.tick()
  oldPos = newPos
  oldScale = newScale
  tick += 1

  local lookingAtSun = world.lookingAtSun()

  if tick % BLINK_RATE == 0 then
    newScale = vec(1, 0, 1)
    newPos = vec(0, (lookingAtSun and 0.25 or 0), 0)
  else
    if lookingAtSun then
      newScale = vec(1, 0.75, 1)
      newPos = vec(0, 0, 0)
    else
      newScale = vec(1, 1, 1)
      newPos = vec(0, 0, 0)
    end
  end
end

function events.RENDER(delta)
  local scale = math.lerp(oldScale, newScale, delta)
  local pos = math.lerp(oldPos, newPos, delta)

  eyes:setPos(pos):setScale(scale)
end

