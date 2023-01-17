sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\quik.lua")
dofile(getScriptPath() .. "\\src\\db.lua")
dofile(getScriptPath() .. "\\src\\db_struct.lua")
dofile(getScriptPath() .. "\\src\\csv.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")

Trades = {}



function main()
    env  = sqlite3.sqlite3()
    conn = env:connect(getScriptPath() .. "\\trades.sqlite")

    if conn then
        Trades = Select(conn, "trades", Tables.trades)
        SaveTableToCSV(getScriptPath() .. "\\trades_db.csv", Trades, Tables.trades)

        conn:close()
    else
        message("Подключение к базе данных не удалось", 2)
    end
    env:close()
end
