local openWingsAnim = animations["models.model"].OpenWings
local closeWingsAnim = animations["models.model"].CloseWings

print(models:getChildren())
local wingRight = models.model.root.Body.WingRight
local wingLeft = models.model.root.Body.WingLeft

local jetpack = models.model.root.Body.Jetpack
local smokePivots = {
   jetpack.SmokePivotRight;
   jetpack.SmokePivotLeft;
}

local function recursivelySetRenderType(mdl, renderType)
   mdl:setPrimaryRenderType(renderType)

   for _, v in pairs(mdl:getChildren()) do
      recursivelySetRenderType(v, renderType)
   end
end

recursivelySetRenderType(wingRight, "TRANSLUCENT_CULL")
recursivelySetRenderType(wingLeft, "TRANSLUCENT_CULL")

closeWingsAnim:play()

local previousWingState
local function toggleWings(state)
   if state then
      if not previousWingState then
         closeWingsAnim:stop()
         openWingsAnim:play()

         previousWingState = state
      end
   elseif not state then
      if previousWingState then
         openWingsAnim:stop()
         closeWingsAnim:play()
         
         previousWingState = state
      end
   end
end

local jetpackOn = 0
local function setFlightTime(duration)
   if duration == 0 or not duration then
      return
   end

   jetpackOn = (duration + 1) * 10 + 5
end

local flightDuration = 0
local listeningForSound = 0

function events.TICK()
   if not player:isGliding() then
      listeningForSound = 0
      flightDuration = 0
      jetpackOn = 0

      return
   end

   if player:isSwingingArm() then
      local item = player:getHeldItem()
      if item:getID() ~= "minecraft:firework_rocket" then
         item = player:getHeldItem(true)
      end

      if item:getID() == "minecraft:firework_rocket" then
         local tag = item:getTag()
         flightDuration = tag.Fireworks.Flight or tag["minecraft:fireworks"]["flight_duration"]
         
         listeningForSound = 100
      end
   end
end

function events.ON_PLAY_SOUND(id)
   if id == "minecraft:entity.firework_rocket.launch" and (listeningForSound > 0) then
      setFlightTime(flightDuration)
   end
end

local steamColor = vec(1, 1, 1)
function events.TICK()
   toggleWings(player:isGliding())

   if jetpackOn > 0 then
      local velocity = jetpack:partToWorldMatrix().c2.xyz * -4
      jetpackOn = jetpackOn - 1

      for _, v in pairs(smokePivots) do
         particles:newParticle("minecraft:dust 1 1 1 2", v:partToWorldMatrix():apply(0,0,0))
            :setVelocity(velocity)
            :setScale(0.75)
            :setLifetime(40)
            :setColor(steamColor - (math.random() / 5))
      end
   end
end

