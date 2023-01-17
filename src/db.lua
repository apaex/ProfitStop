function CreateTable(conn, table, fields, primary)
    local res = {}
    for i, v in ipairs(fields) do
        res[#res + 1] = v.name .. ' ' .. v.type
    end

    local sql = 'CREATE TABLE IF NOT EXISTS ' .. table .. ' (' .. join(res, ',') .. ', PRIMARY KEY(' .. primary ..
        ' ASC))'
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString)
    end
    return status
end

function CreateIndex(conn, table, key)
    local sql = 'CREATE INDEX IF NOT EXISTS ' .. key .. ' ON ' .. table .. ' (' .. key .. ')'
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString)
    end
    return status
end

function Insert(conn, table, t)
    local t1 = foreach(t, function(v) return frame(v, '\'') end)

    local sql = 'INSERT OR REPLACE INTO ' .. table .. ' (' .. join(keys(t1), ',') .. ') VALUES (' .. join(values(t1), ',') .. ')'
 
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString)
    end
    return status
end
