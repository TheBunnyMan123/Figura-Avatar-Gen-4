local WorldStorage = require("libs.TheKillerBunny.WorldStorage")

on["chat_send_message"] = function(msg)
   if msg:match("^%.writeToWorld") then
      WorldStorage.write(player:getPos():floor(), msg:match("^%.writeToWorld (.*)"))
      return ""
   end

   if msg:match("^%.readFromWorld") then
      local dta = WorldStorage.read(vec(msg:match("^%.readFromWorld (%-?[0-9]+) (%-?[0-9]+) (%-?[0-9]+)")))

      if #dta < 50 then
         print(dta)
      end
      host:clipboard(dta)

      print("Copied!")

      return ""
   end

   return msg
end

