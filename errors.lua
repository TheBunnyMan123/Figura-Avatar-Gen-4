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
   labelStyle = component.newStyle():setColor("#ff7b72"),
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
   treeComponent = component.newComponent("\n ↓ ", styles.treeStyle),
   javaComponent = component.newComponent("<Java", styles.treeStyle),
   colon = component.newComponent(" :", styles.gray)
}

local function lexCode(code)
   local compose = component.newComponent("", styles.default)
   for _, v in pairs(lex(code)) do
      if v[1] == "comment" or v[1] == "ws" or v[1] == "mlcom" then
         compose:append(component.newComponent(v[2], styles.comment))
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

local errored = false
function _G.tracebackError(msg)
   local split = splitStr(msg:gsub("\t", ""), "\n")
   local compose = component.newComponent("[Traceback]", styles.labelStyle)

   local longestLineNumCount = 1
   msg:gsub(":[0-9]-:", function(str)
      local num = str:gsub(":", "")
      if longestLineNumCount < #num then
         longestLineNumCount = #num
      end
   end)

   table.remove(split, 2)
   local message = split[1]
   table.remove(split, 1)

   local oldSplit = {}
   for k, v in pairs(split) do
      oldSplit[k] = v
   end

   local iter = 0
   for i = #split, 1, -1 do
      iter = iter + 1
      split[iter] = oldSplit[i]
   end

   for _, v in pairs(split) do
      local java = v:match("%S-.[Jj]ava.")

      local splitTrace = splitStr(v, " ")
      local path = splitStr(splitTrace[1], "/")
      local linenum

      path[#path] = path[#path]:gsub(":[0-9]+:", function(str)
         linenum = tostring(str:match("[0-9]+"))
         return ""
      end)

      local oldPath = {}
      for l, w in pairs(path) do
         oldPath[l] = w
      end
      iter = 0
      for i = #oldPath, 1, -1 do
         iter = iter + 1
         path[i] = oldPath[iter]
      end

      linenum = linenum or "0"

      compose:append(components.treeComponent)
      if java then
         compose:append(component.newComponent(("?"):rep(longestLineNumCount), styles.softBlue))
         compose:append(components.colon)
         compose:append(component.newComponent(v:gsub(".[jJ]ava.: in", ""), styles.javaStyle))
         compose:append(components.javaComponent)
      else
         compose:append(component.newComponent(("0"):rep(math.clamp(longestLineNumCount - #linenum, 0, 5)) .. linenum, styles.lineNumber))
         compose:append(components.colon)
         compose:append(component.newComponent(" " .. path[1], styles.error))
         table.remove(path, 1)

         for _, w in pairs(path) do
            compose:append(component.newComponent("<" .. w, styles.treeStyle))
         end

         compose:append(components.colon)
         table.remove(splitTrace, 1)
         compose:append(component.newComponent(table.concat(splitTrace, " "), styles.inBlock))
      end

   end

   compose:append(component.newComponent("\n[Error]\n", styles.labelStyle))
   compose:append(component.newComponent(" → ", styles.treeStyle))
   compose:append(component.newComponent(message:gsub(".*:[0-9]+ ?", ""):gsub("^.", string.upper), styles.error))

   local script = oldSplit[1]:gsub("/", "."):gsub(":.*$", "")
   local line = tonumber(oldSplit[1]:match(":([0-9]+)%S"))
   local code = avatar:getNBT().scripts[script]
   if code then
      if collection then
         collection:map(code, function(val)
            return val % 256
         end)
      else
         for k in pairs(code) do
            code[k] = code[k] % 256
         end
      end
   end

   if not code then
      return compose:toJson()
   else
      code = string.char(table.unpack(code))
   end

   local oldcode = splitStr(code, "\n")
   code = {}
   local readlines = {}
   for i = -5, 5 do
      if not readlines[math.clamp(line + i, 1, #oldcode)] then
         table.insert(code, oldcode[math.clamp(line + i, 1, #oldcode)])
         readlines[math.clamp(line + i, 1, #oldcode)] = true
      end
   end
   code = table.concat(code, "\n")

   compose:append(component.newComponent("\n[Code]\n", styles.labelStyle))
   compose:append(lexCode(code))

   return compose:toJson()
end

local function newError(msg)
    if errored then return "" end
    errored = true
    local err = tracebackError(msg)

    logJson(err)

    for _, v in pairs(events:getEvents()) do
      v:clear()
    end

    err = err

    ---@type TextJsonComponent
    local newNameplate = {
      {
        text = "TheKillerBunny ",
        color = "white"
      },
      {
        text = "❌",
        color = "#FF0000",
        bold = true,
        hoverEvent = {
          action = "show_text",
          value = parseJson(err)
        }
      },
      {
        text = "${badges}",
        color = "white"
      }
    }

    nameplate.ALL:setText(toJson(newNameplate))
    nameplate.ENTITY:setOutline(true)

    vanilla_model.ALL:setVisible(true)

    local function remove(model)
      for _, v in pairs(model:getChildren()) do
        remove(v)
      end
      model:remove()
    end
    for _, v in pairs(models:getChildren()) do
      remove(v)
    end

    sounds:stopSound()
    particles:removeParticles()
end

if goofy then 
  function events.ERROR(msg)
    local err = tracebackError(msg)
    logJson(err)
    goofy:stopAvatar(err)
    return true
  end
else
  local _require = require
  
  function require(module)
    local successAndArgs = table.pack(pcall(_require, module))
    successAndArgs.n = nil
    if not successAndArgs[1] then
      newError(successAndArgs[2])
    else
      table.remove(successAndArgs, 1)
      return table.unpack(successAndArgs)
    end 
  end

  local _newindex = figuraMetatables.EventsAPI.__newindex
  local _register = figuraMetatables.Event.__index.register
  function figuraMetatables.EventsAPI.__newindex(self, event, func)
    _newindex(self, event, function(...)
      local success, error = pcall(func, ...)
      if not success then
        newError(error)
      else
        return error
      end
    end)
  end
  function figuraMetatables.Event.__index.register(self, func, name)
    _register(self, function(...)
      local success, error = pcall(func, ...)
      if not success then
        newError(error)
      else
        return error
      end
    end, name)
  end
end

