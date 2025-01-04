-- Simple Lua Lexer
-- by BlueMoonJune
-- commission for TheKillerBunny


--[[--------------------------------------------------------

Token Types:
comment, mlcom, word, keyword, number, string, mlstr, op, ws

--------------------------------------------------------]]--

local ops = {
	'...',
	'..',
	'==',
	'~=',
	'<=',
	'>=',
	'=',
	'<',
	'>',
	'+',
	'-',
	'*',
	'/',
	'%',
	',',
	'.',
	'(',
	'[',
	'{',
	')',
	']',
	'}',
	':',
	'#',
}

local keywords = {
	["local"] = true,
	["if"] = true,
	["do"] = true,
	["in"] = true,
	["then"] = true,
	["end"] = true,
	["goto"] = true,
	["for"] = true,
	["while"] = true,
	["function"] = true,
	["return"] = true,
}

local function lex(code)
	local state = nil

	local buffer = ""

	local tokens = {}

	local i = 1
	while i <= #code do
		local c = code:sub(i, i)
		local bfirst = buffer:sub(1,1)
		local blast = buffer:sub(-1, -1)
		if state == "word" and c:find("[^%w"..(bfirst:find("%d") and "." or "_").."]") then
			table.insert(tokens, {bfirst:find("%d") and "number" or "word", buffer})
			state = nil
			buffer = ""
		elseif state == "string" and c == bfirst and blast ~= "\\" then
			buffer = buffer .. c
			table.insert(tokens, {"string", buffer})
			state = nil
			buffer = ""
			goto continue
		elseif (state == "mlstr" or state == "mlcom") and code:sub(i, i + 1) == "]]" then
			buffer = buffer .. "]]"
			table.insert(tokens, {state, buffer})
			state = nil
			buffer = ""
			i = i + 1
			goto continue
		elseif state == "com" and c == "\n" then
			table.insert(tokens, {"comment", buffer})
			state = nil
			buffer = ""
		end

		if not state then
			local oldbuf = buffer
			if c:find("[%w_]") then
				buffer = ""
				state = "word"
			elseif c:find("[\"']") then
				buffer = ""
				state = "string"
			elseif code:sub(i, i + 3) == "--" .. "[[" then
				buffer = ""
				state = "mlcom"
			elseif code:sub(i, i + 1) == "--" then
				buffer = ""
				state = "com"
			elseif code:sub(i, i + 1) == "[[" then
				buffer = ""
				state = "mlstr"
			else
				for _, op in ipairs(ops) do
					if code:sub(i, i + #op - 1) == op then
						table.insert(tokens, {"ws", oldbuf})
						buffer = ""
						table.insert(tokens, {"op", op})
						i = i + #op - 1
						goto continue
					end
				end
			end
			if state then
				table.insert(tokens, {"ws", oldbuf})
			end
		end
		buffer = buffer .. c
		::continue::
		i = i + 1
	end


	for _, t in ipairs(tokens) do
		if t[1] == "word" and keywords[t[2]] then
			t[1] = "keyword"
		end
	end
	return tokens
end

return lex

