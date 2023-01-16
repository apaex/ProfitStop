sqlite3 = require "luasql.sqlite3"

local env  = sqlite3.sqlite3()
local conn = env:connect(getScriptPath() .. "\\mydb.sqlite")

print(env,conn)

status,errorString = conn:execute([[CREATE TABLE sample3 (id INTEGER, name TEXT)]])
print(status,errorString )

status,errorString = conn:execute([[INSERT INTO sample3 values('13','Raj')]])
print(status,errorString )

cursor,errorString = conn:execute([[select * from sample3]])
print(cursor,errorString)

row = cursor:fetch ({}, "a")

while row do
   print(string.format("Id: %s, Name: %s", row.id, row.name))
   row = cursor:fetch (row, "a")
end

-- close everything
cursor:close()
conn:close()
env:close()