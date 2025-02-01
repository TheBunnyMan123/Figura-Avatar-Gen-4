local cache = {}
local scripts = avatar:getNBT().scripts

local collection = collection or {
   map = function(_, table, func)
      for k in pairs(table) do
         table[k] = func(table[k])
      end

      return table
   end
}

---@type table<string, string>
local addons = {
   ["(%S+) ?([%+%-%*/%%^])="] = "%1 = %1 %2"
}

local function split(str, on)
   on = on or " "

   local result = {}
   local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")

   for match in (str .. on):gmatch("(.-)" .. delimiter) do
      result[#result + 1] = match
   end

   return result
end

local function getNonRelativePath(path)
   if not path:match("^%.%./") then
      return path
   end

   local trace = ({pcall(function() error("", 4) end)})[2]:match("stack traceback:(.+)$")
   trace = split(trace:gsub("[ \t]", ""), "\n")
   local script = trace[3]:gsub(":.+$", "")

   return script:gsub("%.", "/"):gsub("/[^/]-$", "/") .. path
end

function require(module)
   local path = getNonRelativePath(module)

   if not cache[path] then
      local bytes = scripts[path]
      local script = string.char(table.unpack(collection:map(bytes, function(b) return b % 256 end)))
      
      for pattern, replacement in pairs(addons) do
         script = script:gsub(pattern, replacement)
      end

      local func = assert(load(script, module, _G))
      cache[path] = table.pack(func())
   end

   return table.unpack(cache[path], 1, cache[path].n)
end

