---@alias TheKillerBunny.on.registerArgs {[number]: string, priority: number?}

local function split(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end


---@class TheKillerBunny.on
local on = {}
local metatable = {__index = on}
local registered = {}
local limiters = {}

---@param key TheKillerBunny.on.registerArgs|string
---@param value function
function metatable.__newindex(_, key, value)
   if type(value) ~= "function" then
      error("you can only register a function")
   end
   if type(key) ~= "table" then
      key = {key}
   end

   local event = string.upper(key[1])
   local priority = key.priority or 1

   table.remove(key, 1)
   key.priority = nil

   registered[event][priority] = registered[event][priority] or {}

   registered[event][priority][key] = value
end

function on.newEvent(name)
   registered[string.upper(name)] = {}

   return function(...)
      local rturn = {priority = 0, value = nil}

      for priority, priorities in ipairs(registered[string.upper(name)] or {}) do
         for key, func in pairs(priorities) do
            for _, limiter in ipairs(key) do
               local splt = split(limiter, ":")
               local fnc = limiters[splt[1]]

               if not fnc(splt[2]) then
                  goto continue
               end
            end

            local val = func(...)

            if priority >= rturn.priority then
               rturn.priority = priority
               rturn.value = val
            end

            ::continue::
         end
      end

      return rturn.value
   end
end

function on.newLimiter(name, func)
   limiters[name] = func
end

for name, event in pairs(events:getEvents()) do
   local invoke = on.newEvent(name)

   event:register(invoke)
end

on = setmetatable(on, metatable)

on[{"chat_send_message", priority = 1}] = function(msg)
   return msg
end
on[{"chat_receive_message", priority = 1}] = function(_, msg)
   return msg
end

return on --[[@as TheKillerBunny.on]]

