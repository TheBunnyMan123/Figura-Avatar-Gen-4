on = require("libs.TheKillerBunny.on")

local currentPlayerPos = vec(0, 0, 0)

local worldTick = 0
local tick = 0
do
   local tickEvent = on.newEvent("tick")
   local worldTickEvent = on.newEvent("world_tick")
   function events.WORLD_TICK()
      worldTick = worldTick + 1
      worldTickEvent(worldTick)
   end

   function events.TICK()
      tick = tick + 1
      tickEvent(tick)
   end
end

local iter = 0
on[{"tick", priority = 2}] = function()
   iter = 0

   currentPlayerPos = player:getPos()
end

on.newLimiter("modulo", function(arg)
   return (tick % arg) == 0
end)

local oldPositions = {}
on.newLimiter("player_moved", function(place)
   iter = iter + 1
   place = place or 1

   oldPositions[iter] = oldPositions[iter] or currentPlayerPos

   local delta = (currentPlayerPos - oldPositions[iter]) * place
   local moved = (delta:floor() / place)

   if moved ~= vec(0, 0, 0) then
      oldPositions[iter] = ((currentPlayerPos * place):floor() / place)
      return true
   end
end)

