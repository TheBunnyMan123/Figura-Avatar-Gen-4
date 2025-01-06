local TextComponents = require("libs.TheKillerBunny.TextComponents")

local color
if client:getDate().month == 10 then
   color = vec(225, 134, 64)
elseif client:getDate().month == 12 then
   color = vec(54, 255, 54)
else
   color = vec(50, 255, 150)
end

avatar:setColor(color / 255)
avatar:setColor(color / 255, "donator")
color = "#" .. vectors.rgbToHex(color / 255)

local styles = {
   main = TextComponents.newStyle():setColor(color),
   fakeBadge = TextComponents.newStyle():setFont("figura:badges"),
   white = TextComponents.newStyle()
}

local compose = TextComponents.newComponent("${badges}")
compose:append(
   TextComponents.newComponent("ᚡ", styles.fakeBadge) -- Arosexual mark because I realized after getting my main mark changed
   :setHoverText(TextComponents.newComponent("Figura Asexual Mark", styles.white))
)
compose:append(TextComponents.newComponent("\n:rabbit: Bunny :rabbit:", styles.main))

local hover = TextComponents.newComponent("@TheKillerBunny", styles.hover)
compose:setHoverText(hover)

nameplate.ALL:setText(compose:toJson())
nameplate.ENTITY
      :setBackgroundColor(0, 0, 0, 0)
      :setOutline(true)
      :setPos(0, -0.1, 0)

