local jukebox = models:newPart("TKBunny$Jukebox", "WORLD")
local page = require("libs.TheKillerBunny.ActionWheelPlusPlus"):newPage("Jukebox", "minecraft:jukebox")

local txts = {}
for k, v in pairs(world.newBlock("minecraft:jukebox", 0, 0, 0):getTextures()) do
   if k == "PARTICLE" then goto continue end
   if not v[1] then goto continue end

   local vanillaTexture = textures:fromVanilla("Jukebox$Vanilla" .. k, v[1] .. ".png")
   local dims = vanillaTexture:getDimensions() / 2
   local texture = textures:newTexture("Jukebox$" .. k, dims:unpack())

   for x = 0, dims.x - 1 do
      for y = 0, dims.y - 1 do
         local targetX = x * 2
         local targetY = y * 2

         if x == dims.x - 1 then targetX += 1 end
         if y == dims.y - 1 then targetY += 1 end

         texture:setPixel(x, y, vanillaTexture:getPixel(targetX, targetY))
      end
   end

   txts[k] = texture
   ::continue::
end

jukebox:newSprite("Jukebox$NORTH")
   :setTexture(txts.NORTH, txts.NORTH:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setPos(0, 0, -8)
jukebox:newSprite("Jukebox$SOUTH")
   :setTexture(txts.SOUTH, txts.SOUTH:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setRot(0, 180)
   :setPos(-8, 0, 0)
jukebox:newSprite("Jukebox$EAST")
   :setTexture(txts.EAST, txts.EAST:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setRot(0, 270)
   :setPos(0, 0, 0)
jukebox:newSprite("Jukebox$WEST")
   :setTexture(txts.WEST, txts.WEST:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setRot(0, 90)
   :setPos(-8, 0, -8)

jukebox:newSprite("Jukebox$TOP")
   :setTexture(txts.UP, txts.UP:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setRot(90, 0)
   :setPos(0, 0, 0)
jukebox:newSprite("Jukebox$BOTTOM")
   :setTexture(txts.DOWN, txts.DOWN:getDimensions():unpack())
   :setSize(8, 8)
   :setLight(15)
   :setRot(270, 180)
   :setPos(-8, -8, 0)

jukebox:setPos(0, 0, 0):setOffsetPivot(12, 8, 12)
jukebox:setVisible(false)

local sound
local soundPos = vec(0, 0, 0)
function pings.stopJukebox()
   if sound then sound:stop() end

   jukebox:setVisible(false)
end

function pings.playJukebox(pos, disc)
   if sound then sound:stop() end

   sound = sounds["music_disc." .. disc]

   soundPos = pos

   sound:setPos(pos):play()
   jukebox:setPos(pos:floor() * 16):setVisible(true)
end

page:newButton("Stop Music", "minecraft:barrier", function()
   pings.stopJukebox()
end)

for _, v in pairs(client.getRegistry("minecraft:sound_event")) do
   local disc = v:match("music_disc.([%w_]+)")
   if not disc then goto continue end

   page:newButton(disc:gsub("^.", string.upper):gsub("_(.)", function(s)
      return "." .. string.upper(s)
   end):gsub("Creator%.Music%.Box", "Creator (Music Box)"), "minecraft:music_disc_" .. disc, function()
      pings.playJukebox(player:getPos():floor() + 0.5, disc)
   end)
   ::continue::
end

on[{"tick", "modulo:20"}] = function()
   if not jukebox:getVisible() then return end
   particles:newParticle("minecraft:note", soundPos, vec(math.random(), math.random(), math.random())):setScale(0.5)
end

