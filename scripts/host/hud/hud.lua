if not goofy then return end

local ui = require("libs.TheKillerBunny.BunnyUI")

local hud = ui.newViewport("HUD", vec(0, 0, 0))
local frontHud = ui.newViewport("HUD", vec(0, 0, 100))

local plazaText = frontHud:newText("plazaText")
plazaText.alignment = "CENTER"
plazaText.position = vec((hud.size.x / 2), 20)
plazaText.outline = true
plazaText.outlineColor = vec(0, 0, 0)
plazaText.fancy = true

local function isInArea(min, max)
  local realmin = vec(math.min(min.x, max.x), math.min(min.y, max.y), math.min(min.z, max.z))
  local realmax = vec(math.max(min.x, max.x), math.max(min.y, max.y), math.max(min.z, max.z))
  local px, py, pz = player:getPos():unpack()
  local x1, y1, z1 = realmin:unpack()
  local x2, y2, z2 = realmax:unpack()
  return (
    ((x1 <= px) and (px <= x2)) and
    ((y1 <= py) and (py <= y2)) and
    ((z1 <= pz) and (pz <= z2))
  )
end

local function thunderdome()
  local sign = world.getBlockState(-468, 72, 144)
  if sign:isAir() then return end

  local data = require("libs.TheKillerBunny.BunnySignLib").read(sign).front
  local bounds = {
    vec(-450, 68, 168),
    vec(-520, 90, 111)
  }
  
  if not isInArea(bounds[1], bounds[2]) then
    return
  end

  if data[3]:match("Ready: ") then
    plazaText.text = toJson{
      {text = ""},
      {
        text = ":zap: ᴛʜᴜɴᴅᴇʀᴅᴏᴍᴇ :zap:",
        color = "gold"
      },
      {
        text = "\nReady: ",
        color = "gray"
      },
      {
        text = data[3]:match("%d+/%d+"),
        color = "green"
      }
    }

    return
  elseif data[3]:match("Wave:") then
    local wave = data[3]:match("%d+")
    local alive = data[4]:match("%d+")

    local enemies = world.getEntities(bounds[1], bounds[2])

    for i = #enemies, 1, -1 do
      if enemies[i]:getType() == "minecraft:player" or (not enemies[i]:isLiving()) then
        table.remove(enemies, i)
      end
    end

    plazaText.text = toJson {
      {text = ""},
      {
        text = ":zap: ᴛʜᴜɴᴅᴇʀᴅᴏᴍᴇ :zap:",
        color = "gold"
      },
      {
        text = "\nWave: ",
        color = "gray"
      },
      {
        text = tostring(wave + 1),
        color = "green"
      },
      {
        text = " |",
        color = "gray"
      },
      {
        text = " Alive: ",
        color = "gray"
      },
      {
        text = tostring(alive),
        color = "green"
      },
      {
        text = "\nEnemies: ",
        color = "gray"
      },
      {
        text = tostring(#enemies),
        color = "red"
      }
    }
  else
    plazaText.text = toJson({
      {text = ""},
      {
        text = ":zap: ᴛʜᴜɴᴅᴇʀᴅᴏᴍᴇ :zap:",
        color = "gold"
      },
      {
        text = "\nWaiting for Players",
        color = "red"
      }
    })

    return
  end

  local enemies = world.getEntities(bounds[1], bounds[2])

  for k, v in pairs(enemies) do
    if v:getType() == "minecraft:player" or v:getType() == "minecraft:arrow" then
      enemies[k] = nil
    end
  end
end

local function infiniplayer()
  local infiniplayerDisplays = {}
  local infiniSong = ""
  local infiniAdder = ""
  local stopped

  if not isInArea(vec(-192, 62, 188), vec(-258, 125, 131)) then
    return
  end

  infiniplayerDisplays = world.getEntities(-237, 63, 175, -229, 64, 174)
  show = infiniplayerDisplays[1]
  for i, v in pairs(infiniplayerDisplays) do
    if v:getType() == "minecraft:text_display" then
      local text = parseJson(v:getNbt().text)
      local song = text.extra[2]
      if song then
        if song.color == "red" then
          stopped = true
          infiniSong = text.extra[2].extra[1]
        end
        if not stopped then
          infiniSong = ((song.extra[1] and song.extra[1].text) or song.extra[1]) or ""
        end
      else
        local adder = parseJson(v:getNbt().text).extra[1].extra[1]
        infiniAdder = (adder.text or adder)
      end
      if stopped then
        if song and song.color ~= "red" then
          infiniAdder = "Playlist: " .. ((song.extra[1] and song.extra[1].text) or song.extra[1])
        end
      end
    end
    ::continue::
  end
  
  plazaText.text = toJson({
    {
      text = ":music2: ɪɴꜰɪɴɪᴘʟᴀʏᴇʀ :music2:\n",
      color = "gray",
      bold = true
    },
    {
      text = tostring(infiniSong) .. "\n",
      color = stopped and "red" or "gold",
      bold = false
    },
    {
      text = tostring(infiniAdder),
      color = "#888888",
      bold = false
    }
  })
end

function events.TICK()
  plazaText.text = toJson({text=""})
  if client.getServerData().ip == "plaza.figuramc.org" then
    thunderdome()
    infiniplayer()
  end
end

