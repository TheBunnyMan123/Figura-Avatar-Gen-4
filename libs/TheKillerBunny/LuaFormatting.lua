--[[
Copyright 2025 Figura Goofballs

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local lib = {}

-- Almost fully taken from XTERM defaults. the only thing not the real default is #0000ff not being #5c5cff
local colorMap16 = {
   "#000000",
   "#cd0000",
   "#00cd00",
   "#cdcd00",
   "#0000ee",
   "#cd00cd",
   "#00cdcd",
   "#e5e5e5",
   "#7f7f7f",
   "#ff0000",
   "#00ff00",
   "#ffff00",
   "#0000ff",
   "#ff00ff",
   "#00ffff",
   "#ffffff"
}

-- 256 color to rgb hex
-- Ported from https://github.com/joejulian/xterm/blob/master/256colres.pl#L64-L76
local function colorToHex(int)
   local r, g, b = 0, 0, 0
   if int >= 0 and int <= 15 then -- System colors
      return colorMap16[int + 1]
   elseif int >= 16 and int <= 231 then -- 6x6x6 RGB cube
      r = (math.floor((int - 16) / 36) * 40 + 55)
      g = (math.floor((int - 16) % 36 / 6) * 40 + 55)
      b = ((int - 16) % 6 * 40 + 55)
   elseif int >= 232 and int <= 255 then -- Grayscale ramp
      local gray = (int - 232) * 10 + 8
      r = gray
      g = gray
      b = gray
   else
      return "#000000"
   end

   r = math.min(255, math.max(0, math.floor(r)))  -- Clamp to 0-255
   g = math.min(255, math.max(0, math.floor(g)))
   b = math.min(255, math.max(0, math.floor(b)))

   local function toHex(c)
      return string.format("%02X", c)
   end

   local hex_color = "#" .. toHex(r) .. toHex(g) .. toHex(b)
   return hex_color
end

print(colorToHex(25))

local function copy(tbl)
   local new = {}

   for key, value in pairs(tbl) do
      if type(value) == "table" then
         new[key] = copy(value)
      else
         new[key] = value
      end
   end

   return new
end

local eightColorMap = {"black", "red", "green", "yellow", "blue", "light_purple", "aqua", "white"}

local ansi24BitColor = "\x1b[38;2;%i;%i;%im"
local ansi256Color = "\x1b[38;5;%im"
local ansi = {
   b = {
      variable = "bold";
      escape = "\x1b[1m";
      unescape = "\x1b[22m";
   },
   i = {
      variable = "italic";
      escape = "\x1b[3m";
      unescape = "\x1b[23m";
   },
   u = {
      variable = "underline";
      escape = "\x1b[4m";
      unescape = "\x1b[24m";
   },
   s = {
      variable = "strikethrough";
      escape = "\x1b[9m";
      unescape = "\x1b[29m";
   }
}

function lib.toAnsi(str)
   local layers = {
      {
         bold = false;
         italic = false;
         underline = false;
         strikethrough = false;
         color = {false, ""};
      }
   }
   local formatLayers = {
      bold = false;
      italic = false;
      underline = false;
      strikethrough = false;
      color = {false, ""}
   }
   local final = ""

   local iter = 0
   local checking = false
   local color = false
   local layer = 2
   while iter <= #str do
      iter = iter + 1
      local char = str:sub(iter, iter)

      if color then
         local hex = str:sub(iter, iter + 6):match("%x%x%x%x%x%x")
         local int = str:sub(iter, iter + 3):match("%d%d?%d?")

         if hex then
            local rgb = tonumber("0x" .. hex)
            local r = bit32.rshift(bit32.band(rgb, 0xff0000), 16)
            local g = bit32.rshift(bit32.band(rgb, 0xff00), 8)
            local b = bit32.band(rgb, 0xff)

            final = final .. ansi24BitColor:format(r, g, b)
            formatLayers.color = {true, ansi24BitColor:format(r, g, b)}
            iter = iter + 5
         elseif int then
            if tonumber(int) <= 7 then
               final = final .. "\x1b[" .. (int + 30) .. "m"
               formatLayers.color = {true, "\x1b[" .. (int + 30) .. "m"}
            else
               final = final .. ansi256Color:format(int)
               formatLayers.color = {true, ansi256Color:format(int)}
            end
            iter = iter + (#int - 1)
         end
         color = false
      elseif checking then
         if char == "[" then
            layers[layer] = {
               bold = formatLayers.bold;
               italic = formatLayers.italic;
               underline = formatLayers.underline;
               strikethrough = formatLayers.strikethrough;
               color = formatLayers.color;
            }

            layer = layer + 1
            checking = false
            goto continue
         elseif char == "]" then
            final = final .. "]"
            checking = false
            goto continue
         elseif char == "$" then
            final = final .. "$"
            checking = false
            goto continue
         end

         if ansi[char] then
            final = final .. ansi[char].escape
            formatLayers[ansi[char].variable] = true
         elseif char == "c" then
            color = true
         end
      else
         if char == "]" then
            if layer == 1 then
               final = final .. "]"
            end

            layer = layer - 1
            final = final .. "\x1b[0m"
            for _, v in pairs(ansi) do
               if layers[layer - 1][v.variable] then
                  final = final .. v.escape
               end
            end
            if layers[layer - 1].color[1] then
               final = final .. layers[layer - 1].color[2]
            end
            formatLayers = copy(layers[layer - 1])
            layers[layer] = nil

            goto continue
         elseif char == "$" then
            checking = true
            goto continue
         end

         final = final .. char
      end

      ::continue::
   end

   return final
end

function lib.toMinecraft(str)
   local layers = {
      {
         bold = false;
         italic = false;
         underline = false;
         strikethrough = false;
         color = "white";
      }
   }
   local compose = {
      bold = false;
      italic = false;
      underline = false;
      strikethrough = false;
      color = "white",
      text = ""
   }
   local newCompose = copy(compose)
   local final = {}

   local iter = 0
   local checking = false
   local color = false
   local layer = 2
   while iter <= #str do
      iter = iter + 1
      local char = str:sub(iter, iter)

      if color then
         local hex = str:sub(iter, iter + 6):match("%x%x%x%x%x%x")
         local int = str:sub(iter, iter + 3):match("%d%d?%d?")

         if hex then
            newCompose.color = "#" .. hex
            iter = iter + 5
         elseif int then
            newCompose.color = colorToHex(tonumber(int))
            iter = iter + (#int - 1)
         end
         color = false
      elseif checking then
         if char == "[" then
            layers[layer] = {
               bold = newCompose.bold;
               italic = newCompose.italic;
               underline = newCompose.underline;
               strikethrough = newCompose.strikethrough;
               color = newCompose.color;
               text = ""
            }
            final[#final + 1] = compose
            compose = layers[layer]

            layer = layer + 1
            checking = false
            goto continue
         elseif char == "]" then
            compose.text = compose.text .. "]"
            checking = false
            goto continue
         elseif char == "$" then
            compose.text = compose.text .. "$"
            checking = false
            goto continue
         end

         if ansi[char] then
            newCompose[ansi[char].variable] = true
         elseif char == "c" then
            color = true
         end
      else
         if char == "]" then
            if layer == 1 then
               compose.text = compose.text .. "]"
            end

            layer = layer - 1
            final[#final + 1] = compose
            compose = copy(layers[layer - 1])
            compose.text = ""
            layers[layer] = nil

            goto continue
         elseif char == "$" then
            checking = true
            goto continue
         end

         compose.text = (compose.text or "") .. char
      end

      ::continue::
   end

   final[#final + 1] = compose

   return final
end

return lib

