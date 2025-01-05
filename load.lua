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
local TextComponents = require("libs.TheKillerBunny.TextComponents")

function string.split(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

for _, v in pairs(models.models:getChildren()) do
   models:addChild(v)
end

for _, v in pairs(listFiles("scripts.priority", true)) do
   require(v)
end
for _, v in pairs(listFiles("scripts.common", true)) do
   require(v)
end
if not host:isHost() then
   for _, v in pairs(listFiles("scripts.guest", true)) do
      require(v)
   end
else
   for _, v in pairs(listFiles("scripts.host", true)) do
      require(v)
   end
end

avatar:store("net_prompter", function()
   local vrs = world.avatarVars()["584fb77d-5c02-468b-a5ba-4d62ce8eabe2"]
   if vrs and vrs.net_acceptor then
      vrs.net_acceptor(net)
   end
end)

