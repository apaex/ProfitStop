function CreateTable(conn, table, fields, primary)
    local _fields = foreach(fields, function(v) return v.name .. ' ' .. v.type end)

    local sql = 'CREATE TABLE IF NOT EXISTS ' .. table .. ' (' .. join(_fields, ',') .. ', PRIMARY KEY(' .. primary ..
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
    local _fields = foreach(fields, function(v) return v.name end)

    local sql = 'SELECT ' .. join(_fields) .. ' FROM ' .. table

    local cursor, errorString = conn:execute(sql)
    if not cursor then
        message(errorString, 2)
        return nil
    end

    local res = {}

    local row = cursor:fetch({})
    while row do
        res[#res + 1] = makePairs(_fields, row)
        row = cursor:fetch({})
    end

    cursor:close()
    return res
end
