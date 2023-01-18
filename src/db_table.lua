DBTable = {}

function DBTable:Create()
    return self:CreateTable() and self:CreateIndex()
end

function DBTable:CreateTable()
    local _fields = foreach(self.fields, function(v) return v.name .. ' ' .. v.type end)

    local sql = 'CREATE TABLE IF NOT EXISTS ' ..
        self.name .. ' (' .. join(_fields, ',') .. ', PRIMARY KEY(' .. self.primary .. ' ASC))'
    local status, errorString = self.conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function DBTable:CreateIndex()
    local sql = 'CREATE INDEX IF NOT EXISTS ' .. self.index .. ' ON ' .. self.name .. ' (' .. self.index .. ')'
    local status, errorString = self.conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function DBTable:Insert(t)
    local t1 = foreach(t, function(v) return quote(v) end)

    local sql = 'INSERT OR REPLACE INTO ' ..
        self.name .. ' (' .. join(keys(t1), ',') .. ') VALUES (' .. join(values(t1), ',') .. ')'

    local status, errorString = self.conn:execute(sql)
    if not status then
        message(errorString, 2)
    end
    return status
end

function DBTable:Select()
    local _fields = foreach(self.fields, function(v) return v.name end)

    local sql = 'SELECT ' .. join(_fields) .. ' FROM ' .. self.name

    local cursor, errorString = self.conn:execute(sql)
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
