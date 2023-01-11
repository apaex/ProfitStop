function SaveTableToCSV(filename, table, fields)

    local f, errorString = io.open(filename, "w")
    if f == nil then
        message("File reading error: " .. errorString, 3)
        return
    end

    local count = 0
    local line
    local headers = keys(fields)

    for key, row in pairs(table) do
        if count == 0 then
            headers = headers or keys(row) -- если структура не задана, то возьмем из первой строки
            line = join(headers, ';')
            f:write(line .. "\n")
        end

        tmp_data = {}
        for i, v in ipairs(headers) do
            tmp_data[i] = row[v]
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
