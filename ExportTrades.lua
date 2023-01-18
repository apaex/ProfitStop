sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\quik.lua")
dofile(getScriptPath() .. "\\src\\db_table.lua")
dofile(getScriptPath() .. "\\src\\db.lua")
dofile(getScriptPath() .. "\\src\\csv.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")

function main()
    env          = sqlite3.sqlite3()
    DBTable.conn = env:connect(DB_FILE)

    if DBTable.conn then
        local trades, fields = db.trades:GetGroupTraders()
        DebugWrite(fields)
        if trades then
            SaveTableToCSV(getScriptPath() .. "\\trades_db.csv", trades, fields)
        else
            message("Не удалось сформировать группировку сделок", 2)
        end
        DBTable.conn:close()
    else
        message("Подключение к базе данных не удалось", 2)
    end
    env:close()
end
