local lib = {}

local function getText(str)
  local _, json = pcall(parseJson, str)

  return json.text or str or ""
end

---Reads a sign
---@param state BlockState
---@return {front: string[], back: string[]}
function lib.read(state)
  local nbt = state:getEntityData()
  local final = {
    front = {},
    back = {}
  }

  local version = client.getVersion()

  if client.compareVersions(version, "1.20") < 1 then
    final.front[1] = getText(nbt.Text1)
    final.front[2] = getText(nbt.Text2)
    final.front[3] = getText(nbt.Text3)
    final.front[4] = getText(nbt.Text4)
  else
    local front = nbt.front_text
    local back = nbt.back_text

    front = front.messages or {}
    back = back.messages or {}

    final.front[1] = getText(front[1])
    final.front[2] = getText(front[2])
    final.front[3] = getText(front[3])
    final.front[4] = getText(front[4])
    
    final.back[1] = getText(back[1])
    final.back[2] = getText(back[2])
    final.back[3] = getText(back[3])
    final.back[4] = getText(back[4])
  end

  return final
end

return lib

