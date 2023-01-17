function CreateTable(conn, table, fields, primary)
    local res = {}
    for i, v in ipairs(fields) do
        res[#res + 1] = v.name .. ' ' .. v.type
    end

    local sql = 'CREATE TABLE IF NOT EXISTS ' .. table .. ' (' .. join(res, ',') .. ', PRIMARY KEY(' .. primary ..
        ' ASC))'
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function CreateIndex(conn, table, key)
    local sql = 'CREATE INDEX IF NOT EXISTS ' .. key .. ' ON ' .. table .. ' (' .. key .. ')'
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function Insert(conn, table, t)
    local t1 = foreach(t, quote)

    local sql = 'INSERT OR REPLACE INTO ' ..
        table .. ' (' .. join(keys(t1), ',') .. ') VALUES (' .. join(values(t1), ',') .. ')'

    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function Select(conn, table, fields)

    local fields_names = foreach(fields, function(v) return v.name end)

    local cursor, errorString = conn:execute('SELECT ' .. join(fields_names) .. ' FROM ' .. table)
    if not cursor then
        message(errorString, 2)
        return nil
    end

    local row = cursor:fetch({})
    local res = {}

    while row do
        res[#res + 1] = makePairs(fields_names, row)
        row = cursor:fetch({})
    end

    cursor:close()
    return res
end
