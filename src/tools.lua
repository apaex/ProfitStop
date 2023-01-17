

function copyFields(t, fields)
	local res = {}
	for i, v in ipairs(fields) do
		res[v] = t[v]
	end
	return res
end

-- получаем все ключи таблицы
function keys(t)
	local res = {}
	for key, v in pairs(t) do
		res[#res + 1] = key
	end
	return res
end

-- получаем все значения таблицы
function values(t)
	local res = {}
	for key, v in pairs(t) do
		res[#res + 1] = v
	end
	return res
end

function makePairs(keys, values)
	local t = {}
	for i = 1, #keys do
		t[keys[i]] = values[i]
	end
	return t
end

function join(t, c)
	local s = ""
	for key, v in pairs(t) do
		s = s .. tostring(v) .. c
	end
	return #s > 0 and string.sub(s, 1, #s - 1) or "";
end

function split(s, c)
	local result = {}

	local index = 1
	for s in string.gmatch(s, "[^" .. c .. "]*") do
		result[index] = s

		index = index + 1
	end

	return result
end

function foreach(t, func)
	local res = {}
	for k, v in pairs(t) do
		res[k] = func(v)
	end
	return res
end

function nz(v, nv)
	return v ~= nil and v or nv or 'nil'
end

function quote(s, c)
	c = c or '\''
    return c .. s .. c
end

