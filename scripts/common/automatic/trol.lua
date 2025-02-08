local trolEmoji = textures:fromVanilla("meme_emoji", "figura:textures/font/emojis/meme.png")
local dims = trolEmoji:getDimensions()

local emojiX, emojiY = math.random(0, dims.x / 8 - 1), math.random(0, dims.y / 8 - 1)

if emojiY == 2 then
   emojiX = math.random(0, 1)
end

local emoji = {}

for y = (emojiY * 8), ((emojiY * 8) + 7) do
   for x = (emojiX * 8), ((emojiX * 8) + 7) do
      local pixel = trolEmoji:getPixel(x, y)
      emoji[#emoji + 1] = {
         text = "█",
         color = "#" .. vectors.rgbToHex(pixel.w > 0 and pixel.xyz or vec(0, 0, 0))
      }
   end
   emoji[#emoji + 1] = {
      text = "\n",
      color = "white"
   }
end

printJson(toJson(emoji))

