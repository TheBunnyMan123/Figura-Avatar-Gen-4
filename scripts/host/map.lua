local TextComponents = require("libs.TheKillerBunny.TextComponents")
local waypoints = {}

local page = require("libs.TheKillerBunny.ActionWheelPlusPlus"):newPage("Waypoints", "minecraft:nether_star")

local color = vec(1, 1, 1)
local action = "add"
local icon = nil
local name = "name"
page:newText("Name", "minecraft:name_tag", function(newName)
   name = newName
end, "name")
page:newText("Icon", "minecraft:painting", function(newIcon)
   icon = newIcon

   if newIcon == "_" then
      icon = nil
   end
end, "_")
page:newColor("Color", "minecraft:white_dye", function(col)
   color = col
end, vec(1, 1, 1))
page:newRadio("Action", "minecraft:writable_book", function(opt)
   action = opt
end, {"add", "remove"})
page:newButton("Execute", "minecraft:command_block", function()
   local serverData = client.getServerData()
   local server = serverData.ip or serverData.name
   local dimension = world.getDimension()

   waypoints[dimension] = waypoints[dimension] or {}

   if action == "add" then
      waypoints[dimension][name] = {
         color = "#" .. vectors.rgbToHex(color),
         pos = {player:getPos():floor():unpack()},
         icon = icon
      }

      file:writeString("waypoints/" .. server:gsub("[/\\]", "_") .. ".json", toJson(waypoints), "utf8")
   elseif action == "remove" then
      waypoints[dimension][name] = nil

      file:writeString("waypoints/" .. server:gsub("[/\\]", "_") .. ".json", toJson(waypoints), "utf8")
   end
end)

on[{"tick", "modulo:20"}] = function()
   file:mkdir("waypoints")
   local serverData = client.getServerData()
   local server = serverData.ip or serverData.name

   if waypoints.server ~= server then
      if not file:exists("waypoints/" .. server:gsub("[/\\]", "_") .. ".json") then
         file:writeString("waypoints/" .. server:gsub("[/\\]", "_") .. ".json", toJson{server = server}, "utf8")
      end

      waypoints = parseJson(file:readString("waypoints/" .. server:gsub("[/\\]", "_") .. ".json", "utf8"))
   end
end

local goofy = goofy
if not goofy then
   goofy = {getAvatarColor = function() end}
end

--{{ options
local STEP = 1 -- How many blocks to step
local SIZE = vec(64, 64) -- How big the map is
local POS = vec(3, 3) -- Top left corner of the map
local HEAVY_OPTIMIZATION = false -- Heavily optimize the color generation - This may come with appearance tradeoffs
local TIME_PER_FRAME = 10 -- How long to spend calculating the map per frame (in milliseconds)
local HALF_SIZE = SIZE / 2
local SCALE = 1.5 -- Map scale
local SKY_COLOR = vec(0.36862, 0.64705, 1, 0.5)
local SHADE_LAVA = true -- Minecraft maps do not do this but it makes it look so much better
local CACHE_AGE = 1000 * 10 -- The amount of time a color can stay in the cache
local WATER_BASE = 1.25 -- The base of the water multiplier
local WATER_DIVISOR = 11.5 -- The amount to divide the water multiplier by
--}}

local mc21 = (client.compareVersions(client.getVersion(), "1.21") >= 0)

local colorCache = {}

local water_blocks = {
   ["minecraft:water"] = true,
   ["minecraft:flowing_water"] = true,
   ["minecraft:seagrass"] = true,
   ["minecraft:tall_seagrass"] = true,
   ["minecraft:kelp"] = true,
   ["minecraft:kelp_plant"] = true,
   ["minecraft:lava"] = SHADE_LAVA and true
}

local white = textures:newTexture("TKBunny$Map$White", 1, 1)
white:setPixel(0, 0, vec(1, 1, 1, 1))

local mdl = models:newPart("TKBunny$Map", "HUD")
local map = textures:newTexture("TKBunny$Map", (SIZE + 4):unpack())
mdl:newSprite("map")
      :setTexture(map, SIZE:unpack())
      :setScale(SCALE)
      :setPos(-POS.xy_ * SCALE)
      :setLight(15)

map:fill(0, 0, SIZE.x + 4, SIZE.y + 4, 0, 0, 0)

---@type RenderTask[][]
local tasks = {}

local randomCache = {}
local function colorFromString(str)
   if randomCache[str] then
      return randomCache[str]
   end

   local num = collection:sum({string.byte(str, 1, #str)})

   math.randomseed(num or 0)
   local r = math.random()
   local g = math.random()
   local b = math.random()

   randomCache[str] = vec(r, g, b)

   return vec(r, g, b)
end

local function getWaterMultiplier(depthFactor, x, y)
   local xEven = x % 2 == 0
   local yEven = y % 2 == 0

   if (depthFactor % 2 ~= 0) or HEAVY_OPTIMIZATION then
      return WATER_BASE - depthFactor / WATER_DIVISOR
   end

   if (not xEven and not yEven) or (xEven and yEven) then
      return WATER_BASE - (depthFactor - 1) / WATER_DIVISOR
   else
      return WATER_BASE - (depthFactor + 1) / WATER_DIVISOR
   end
end

local function getColor(x, y, noiter)
   x = math.floor(x)
   y = math.floor(y)

   local minHeight, height = world.getBuildHeight()
   local maxHeight = height

   height = raycast:block(x + 0.5, maxHeight, y + 0.5, x + 0.5, minHeight, y + 0.5, "OUTLINE", "ANY"):getPos().y
  
   local color
   local loop = true
   while loop do
      local block = world.getBlockState(x, height, y)
      color = block:getMapColor()

      if color == vec(0, 0, 0) and block:isTranslucent() then
         height = height - 1

         if height < minHeight then
            return SKY_COLOR, height
         end
      else
         if noiter then
            break
         end

         local water = water_blocks[block:getID()]
         local oldHeight = height

         if water then
            height = raycast:block(x, height, y, x, minHeight, y, "COLLIDER", "NONE"):getPos().y
         end

         local depth = oldHeight - height

         if water then
            height = height + 1

            local depthFactor = math.clamp(math.floor(depth / 2), 1, 5) 
            color = color * getWaterMultiplier(depthFactor, x, y)
         end

         local bright = world.getBlockState(x, height, y - 1):isAir() and not water
         local dark, darkHeight
         if HEAVY_OPTIMIZATION then
            dark = raycast:block(x, height + 1, y - 1, x, maxHeight, y - 1, "VISUAL", "ANY")
            dark = not dark:isAir()
         else
            dark, darkHeight = getColor(x, y - 1, true)

            dark = dark ~= SKY_COLOR
            dark = dark and (darkHeight > height)
         end
         
         dark = dark and not water

         if not bright and not dark then
            color = color / vec(1.15, 1.15, 1.15)
         end
         if dark then
            color = color / vec(1.4, 1.4, 1.4)
         end

         loop = false
      end
   end

   return vec(
      math.clamp(color.x, 0, 1),
      math.clamp(color.y, 0, 1),
      math.clamp(color.z, 0, 1)
   ), height
end

local styles = {
   white = TextComponents.newStyle()
}

local infoTask = mdl:newText("info")
      :setPos(-POS.xy_ - HALF_SIZE.xy_:copy():mul(SCALE, SCALE * 2, 1):add(SCALE, 9, 0))
      :setAlignment("CENTER")
      :setOutline(true)
      :setLight(15)

on[{"tick", "player_moved:1"}] = function()
   local pPos = player:getPos():floor()
   local compose = TextComponents.newComponent(tostring(pPos):gsub("[{}]", ""), styles.white)

   local biome = world.getBiome(pPos).id:gsub("^.-:(.)", string.upper):gsub("_(.)", function(s)
      return " " .. string.upper(s)
   end)
   local shortened = biome:match("^" .. (".?"):rep(15))
   if biome ~= shortened then
      shortened = shortened .. "..."
   end

   compose:append(TextComponents.newComponent("\n" .. shortened, styles.white))

   infoTask:setText(compose:toJson())
end

local function isInRange(pos, min, max)
   local clamped = vec(
      math.clamp(pos.x, min.x, max.x),
      math.clamp(pos.y, min.y, max.y),
      math.clamp(pos.z, min.z, max.z)
   )


   return (
      pos.x == clamped.x and
      pos.z == clamped.z
   ), clamped
end

-- I stole this from 4P5's figmap
local amount = mc21 and 5 or 68
local function rotateSpriteAroundPos(rot, pos, scale)
   local mat = matrices.mat4()
         :scale(scale, scale, 1)
         :translate(amount * scale, amount * scale)
         :rotate(0, 0, rot)
         :translate(-amount * scale, -amount * scale)
         :translate(pos)
         :translate(amount * scale, amount * scale)

   return mat
end

local indicatorTexture = textures:fromVanilla("map_indicators", "minecraft:textures/map/map_icons.png")
local mc21PlayerIndicator = textures:fromVanilla("map_indicator_player", "minecraft:textures/map/decorations/player.png")
local mc21PlayerOffMapIndicator = textures:fromVanilla("map_indicator_player_off_map", "minecraft:textures/map/decorations/player_off_map.png")
local mc21BannerIndicator = textures:fromVanilla("map_indicator_banner", "minecraft:textures/map/decorations/white_banner.png")

local inMdl = mdl:newPart("indicators")
on[{"tick", "modulo:4"}] = function(tick)
   for _, v in pairs(inMdl:getTask()) do
      v:remove()
   end

   local pPos = player:getPos()
   local minPos = pPos - HALF_SIZE.xxy
   local maxPos = pPos + HALF_SIZE.xxy

   if waypoints then
      for name, data in pairs(waypoints[world.getDimension()] or {}) do
         local wayPos = vec(table.unpack(data.pos))

         local _, clamped = isInRange(wayPos.x_z, minPos.x_z + 2, maxPos.x_z)
         local index = "§§banner_" .. name

         local onMapPos = clamped.xz - pPos.xz + HALF_SIZE
         onMapPos = onMapPos * SCALE
         onMapPos = onMapPos + POS
         onMapPos = onMapPos.xy_
         onMapPos.z = 50

         if mc21 then
            inMdl:newSprite(index)
                  :setTexture(mc21BannerIndicator, mc21BannerIndicator:getDimensions():unpack())
                  :setUVPixels(72, 0)
                  :setColor(vectors.hexToRGB(data.color))
                  :setMatrix(rotateSpriteAroundPos(0, -onMapPos, SCALE))
                  :setLight(15)
         else
            inMdl:newSprite(index)
                  :setTexture(indicatorTexture, indicatorTexture:getDimensions():unpack())
                  :setUVPixels(80, 0)
                  :region(8, 8)
                  :setColor(vectors.hexToRGB(data.color))
                  :setMatrix(rotateSpriteAroundPos(0, -onMapPos, 8/128 * SCALE))
                  :setLight(15)
         end
      end
   end

   for _, v in pairs(world.getPlayers()) do 
      local inRange, clamped = isInRange(v:getPos(), minPos, maxPos)
      local uuid = v:getUUID()

      colorCache[uuid] = colorCache[uuid] or {age = -CACHE_AGE - 1, color = vec(0, 0, 0)}
      if (colorCache[uuid].age - tick) < CACHE_AGE then
         colorCache[uuid].age = tick

         local avatarColor = goofy:getAvatarColor(uuid)
         colorCache[uuid].color = avatarColor and vectors.hexToRGB(avatarColor) or colorFromString(v:getName())
      end

      local onMapPos = (-math.map(clamped.xz_ - pPos.xz_, -HALF_SIZE.xxy, HALF_SIZE.xxy, HALF_SIZE.xxy, -HALF_SIZE.xxy) * SCALE) + POS.xy_ + (HALF_SIZE.xy_ * SCALE)
      onMapPos = onMapPos.xy_:add(0, 0, 100)

      local rot = math.round((v:getRot().y) / 22.5) * 22.5

      rot = rot - 180

      if mc21 then
         if inRange then
            inMdl:newSprite(v:getUUID())
                  :setTexture(mc21PlayerIndicator, 8, 8)
                  :region(8, 8)
                  :setColor(colorCache[uuid].color)
                  :setMatrix(rotateSpriteAroundPos(rot, -onMapPos, SCALE))
                  :setLight(15)
         else
            inMdl:newSprite(v:getUUID())
                  :setTexture(mc21PlayerOffMapIndicator, 8, 8)
                  :region(8, 8)
                  :setColor(colorCache[uuid].color)
                  :setMatrix(rotateSpriteAroundPos(0, -onMapPos, SCALE))
                  :setLight(15)
         end
      else
         if inRange then
            inMdl:newSprite(v:getUUID())
                  :setTexture(indicatorTexture, 128, 128)
                  :region(8, 8)
                  :setUVPixels(0, 0)
                  :setColor(colorCache[uuid].color)
                  :setMatrix(rotateSpriteAroundPos(rot, -onMapPos, 8/128 * SCALE))
                  :setLight(15)
         else
            inMdl:newSprite(v:getUUID())
                  :setTexture(indicatorTexture, 128, 128)
                  :setUVPixels(48, 0)
                  :region(8, 8)
                  :setColor(colorCache[uuid].color)
                  :setMatrix(rotateSpriteAroundPos(0, -onMapPos, 8/128 * SCALE))
                  :setLight(15)
         end
      end
   end
end

local function isPosVisible(pos)
   local z = vectors.toCameraSpace(pos).z

   return (mc21 and z < 0) or (not mc21 and z > 0)
end

local waypointTasks = {}
on["world_render"] = function(delta)
   for _, v in pairs(waypointTasks) do
      v:remove()
   end
   if not player:isLoaded() then return end
   local dimension = world.getDimension()

   for name, data in pairs(waypoints[dimension] or {}) do
      local wayPos = vec(table.unpack(data.pos))
      if isPosVisible(wayPos + 0.5) then
         local screenPos = math.map(vectors.worldToScreenSpace(wayPos + 0.5).xy, vec(-1, -1), vec(1, 1), vec(0, 0), -client.getScaledWindowSize())
         local dist = (wayPos - player:getPos()):length()

         if dist >= 1000000 then
            dist = math.floor(dist / 1000000) .. "Mm"
         elseif dist >= 1000 then
            dist = math.floor(dist / 1000) .. "km"
         else
            dist = math.floor(dist) .. "m"
         end

         local offset = client.getTextWidth(data.icon or "◆") - 7
         waypointTasks[name] = mdl:newText(name .. "_icon")
               :setText(toJson {
                  text = data.icon or "◆",
                  color = data.color
               })
               :setPos(screenPos.xy_ + vec(0, 9, 0))
               :setScale(2)
               :setAlignment("CENTER")
               :setOutline(true)
               :setLight(15)
         waypointTasks[name .. "_name"] = mdl:newText(name .. "_name")
               :setText(toJson {
                  text = name,
               })
               :setPos(screenPos.xy_ + vec(-9 - offset, 4.5, 10000))
               :setAlignment("LEFT")
               :setOutline(true)
               :setLight(15)
         waypointTasks[name .. "_dist"] = mdl:newText(name .. "_dist")
               :setText(toJson {
                  text = dist,
               })
               :setPos(screenPos.xy_ + vec(9, 4.5, 0))
               :setAlignment("RIGHT")
               :setOutline(true)
               :setLight(15)
      end
   end
end

local x = 1
local y = 1
on["render"] = function()
   local time = client.getSystemTime()
   local pPos = player:getPos():floor()
   
   while time >= (client.getSystemTime() - TIME_PER_FRAME) do
      x = x + 1
      if x > SIZE.x then
         x = 1
         y = y + 1
      end
      if y > SIZE.y then
         y = 1
      end

      local color = getColor(pPos.x + (x * STEP) - (HALF_SIZE.x * STEP), pPos.z + (y * STEP) - (HALF_SIZE.y * STEP))

      tasks[x] = tasks[x] or {}

      map:setPixel(x + 1, y + 1, color)
   end
   map:update()
end

