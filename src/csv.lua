function SaveTableToCSV(filename, t, headers)

    local f, errorString = io.open(filename, "w")
    if f == nil then
        message("File reading error: " .. errorString, 3)
        return
    end

    local count = 0
    local line

    for key, row in pairs(t) do
        if count == 0 then
            headers = headers or keys(row) -- если структура не задана, то возьмем из первой строки
            line = join(headers, ';')
            f:write(line .. "\n")
        end

        local tmp_data = {}
        for i, v in ipairs(headers) do
            local data = row[v]
            if data == nil then
                tmp_data[i] = ""
            elseif v == 'datetime' then
                tmp_data[i] = os.date("%d.%m.%Y %X", data)
            elseif type(data) == "number" then
                tmp_data[i] = string.gsub(tostring(data), "[.]", ",")
                
            elseif type(data) == "string" then
                tmp_data[i] = data
            else
                tmp_data[i] = tostring(data)
            end
        end

        line = join(tmp_data, ';')
        f:write(line .. "\n")

        count = count + 1
    end

    f:close()
end

function LoadTableFromCSV(filename)

    local f, errorString = io.open(filename, "r")
    if f == nil then
        message("File reading error: " .. errorString, 3)
        return
    end

    local table = {}
    local count = 0
    local headers = {}
    local row = {}

    for line in f:lines() do
        if count == 0 then
            headers = split(tostring(line), ";")
        else
            row = split(tostring(line), ";")
            row = makePairs(headers, row)

            table[#table + 1] = row
        end

        count = count + 1
    end

    f:close()

    return table

end

function structureData(t, fields)
    local res = {}
    for key, v in pairs(t) do
        if fields[key] == 'number' then
            res[key] = tonumber(v)
        else
            res[key] = v
        end
    end
    return res
end

function destructureData(t, fields)
    local res = {}
    for key, v in pairs(t) do
        if fields[key] == 'number' then
            res[key] = tostring(v)
        else
            res[key] = v
        end
    end
    return res
end

function makeStructure(t, key, fields)
    if t == nil then
        return nil
    end

    local res = {}
    for i, v in ipairs(t) do
        v = structureData(v, fields)
        if v[key] ~= nil then
            res[v[key]] = v
        end
    end
    return res
end
