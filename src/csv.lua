function SaveTableToCSV(filename, table)

    local f, errorString = io.open(filename, "w")
    if f == nil then
        message("File reading error: " .. errorString, 3)
        return
    end

    local count = 0
    local line

    for key, row in pairs(table) do
        if count == 0 then
            DebugWrite(keys(row))
            line = join(keys(row), ';')
            f:write(line .. "\n")
        end

        line = join(values(row), ';')
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
