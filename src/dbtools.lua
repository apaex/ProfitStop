SqlTypeMap =
{
    number = 'INTEGER',
    string = 'TEXT',
    table = 'DATETIME'
}

function CreateTable(conn, table, fields, primary)
    local res = {}
    for i, v in ipairs(fields) do
        res[#res + 1] = v.name .. ' ' .. SqlTypeMap[v.type]
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
    local t1 = prepareData(t)
    local sql = 'INSERT INTO ' .. table .. ' (' .. join(keys(t1), ',') .. ') VALUES (' .. join(values(t1), ',') .. ')'
    message(sql)
    local status, errorString = conn:execute(sql)
    if not status then
        message(errorString)
    end
    return status
end

function prepareData(t)
    local res = {}
    for key, v in pairs(t) do
        if type(v) == 'number' then
            res[key] = '\'' .. tostring(v) .. '\''
        elseif type(v) == 'table' then
            res[key] = string.format("'%d-%d-%d %d:%d:%d'", v.year, v.month, v.day, v.hour, v.min, v.sec)
        else
            res[key] = '\'' .. v .. '\''
        end
    end
    return res
end
