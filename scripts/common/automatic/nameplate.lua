local format = require("libs.TheKillerBunny.LuaFormatting")
local color = vec(50, 255, 150)

avatar:setColor(color / 255)
avatar:setColor(color / 255, "donator")
color = vectors.rgbToHex(color / 255)

nameplate.ALL:setText(toJson(format.toMinecraft [=[$${badges}
:rabbit: $c32ff96[Bunny] :rabbit:]=]))

nameplate.ENTITY
      :setBackgroundColor(0, 0, 0, 0)
      :setOutline(true)

