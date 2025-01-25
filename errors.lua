--[[
Copyright 2024 TheKillerBunny

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

if avatar:getMaxInitCount() < 12000000 then
   tracebackError = function(...) return ... end
   return
end

local component = require("libs.TheKillerBunny.TextComponents")
local lex = require("libs.BlueMoonJune.lex")

local figcolors = {
   AWESOME_BLUE = "#5EA5FF",
   PURPLE = "#A672EF",
   BLUE = "#00F0FF",
   SOFT_BLUE = "#99BBEE",
   RED = "#FF2400",
   ORANGE = "#FFC400",

   CHEESE = "#F8C53A",

   LUA_LOG = "#5555FF",
   LUA_ERROR = "#FF5555",
   LUA_PING = "#A155DA",

   DEFAULT = "#5AAAFF",
   DISCORD = "#5865F2",
   KOFI = "#27AAE0",
   GITHUB = "#FFFFFF",
   MODRINTH = "#1BD96A",
   CURSEFORGE = "#F16436",
}
local styles = {
   default = component.newStyle(),
   labelStyle = component.newStyle():setColor("#ff3640"),--:setColor("#ff7b72"),
   treeStyle = component.newStyle():setColor("#797979"),
   javaStyle = component.newStyle():setColor("#f89820"),
   softBlue = component.newStyle():setColor(vectors.hexToRGB(figcolors.SOFT_BLUE)),
   gray = component.newStyle():setColor("gray"),
   lineNumber = component.newStyle():setColor(vectors.hexToRGB(figcolors.BLUE)),
   error = component.newStyle():setColor(vectors.hexToRGB(figcolors.LUA_ERROR)),
   inBlock = component.newStyle():setColor("#896767"),
   comment = component.newStyle():setColor("#888888"),
   boolean = component.newStyle():setColor("#ff8836"),
   word = component.newStyle():setColor("#36ffff"),
   keyword = component.newStyle():setColor("#3636ff"),
   string = component.newStyle():setColor("#36ff36"),
   op = component.newStyle():setColor("#ffffff")
}
local components = {
   lineBegin = component.newComponent("\n| ", styles.treeStyle),
   treeComponent = component.newComponent("\n| ", styles.treeStyle),
   javaComponent = component.newComponent("<Java", styles.treeStyle),
   colon = component.newComponent(" : ", styles.gray)
}

local function lexCode(code)
   code = code .. " "
   local compose = component.newComponent("| ", styles.comment)
   for _, v in pairs(lex(code)) do
      if v[1] == "comment" or v[1] == "ws" or v[1] == "mlcom" then
         compose:append(component.newComponent(v[2]:gsub("\n", "\n| "), styles.comment))
      elseif v[1] == "word" or v[1] == "number" then
         if v[1] == "true" or v[1] == "false" then
            compose:append(component.newComponent(v[2], styles.boolean))
         else
            compose:append(component.newComponent(v[2], styles.word))
         end
      elseif v[1] == "keyword" then
         compose:append(component.newComponent(v[2], styles.keyword))
      elseif v[1] == "string" or v[1] == "mlstring" then
         compose:append(component.newComponent(v[2], styles.string))
      elseif v[1] == "op" then
         compose:append(component.newComponent(v[2], styles.op))
      end
   end

   return compose
end

local function splitStr(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

local betterErrors = require("libs.TheKillerBunny.BetterErrors")

betterErrors.setFunc(function (script, reason, stacktrace, code, username, line)
   local oldtrace = stacktrace
   stacktrace = {}
   for i = #oldtrace, 1, -1 do
      table.insert(stacktrace, oldtrace[i])
   end

   local compose = component.newComponent(username .. "'s error", styles.labelStyle)
   compose:append(components.lineBegin)
   compose:append(component.newComponent(reason:gsub("^.", string.upper), styles.error))
   
   compose:append(component.newComponent("\n\nStack traceback:", styles.labelStyle))
   for _, v in pairs(stacktrace) do
      compose:append(components.lineBegin)
      compose:append(component.newComponent(tostring(v.line), styles.lineNumber))
      compose:append(components.colon)

      if v.script == "java/?" then
         compose:append(component.newComponent("?", styles.javaStyle))
         compose:append(components.javaComponent)
      else
         local splitScript = splitStr(v.script, "/")
         for k = #splitScript, 1, -1 do
            local w = splitScript[k]

            if k == #splitScript then
               compose:append(component.newComponent(w, styles.error))
            else
               compose:append(component.newComponent("<" .. w, styles.treeStyle))
            end
         end
      end

      compose:append(components.colon)
      compose:append(component.newComponent(v.chunk, styles.inBlock))
   end

   local codeTbl = avatar:getNBT().scripts[script:gsub("/", ".")]
   if codeTbl then
      if collection then
         collection:map(codeTbl, function(val)
            return val % 256
         end)
      else
         for k in pairs(codeTbl) do
            codeTbl[k] = codeTbl[k] % 256
         end
      end

      local oldCode = splitStr(string.char(table.unpack(codeTbl)), "\n")
      code = ""

      local readLines = {}
      for i = -1, 1 do
         local lineNum = math.clamp(line + i, 1, #oldCode)
         if not readLines[lineNum] then
            code = code .. oldCode[lineNum] .. "\n"
         end
         readLines[lineNum] = true
      end
      code = code:gsub("\n$", "")
   end

   if not code then
      return compose:toJson()
   end
   
   compose:append(component.newComponent("\n\nCode:\n", styles.labelStyle))
   code = lexCode(code)

   compose:append(code)

   return compose:toJson()
end)

_G.tracebackError = betterErrors.tracebackError

