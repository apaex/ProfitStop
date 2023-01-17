sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\quik.lua")
dofile(getScriptPath() .. "\\src\\db.lua")
dofile(getScriptPath() .. "\\src\\db_struct.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true



function main()
    env  = sqlite3.sqlite3()
    conn = env:connect(getScriptPath() .. "\\trades.sqlite")
    if conn then
        if CreateTable(conn, 'trades', Tables.trades, 'trade_num') and CreateIndex(conn, 'trades', 'order_num') then
            GetTrades()
            while IsRun do end
            
        else
            message("Не удалось создать структуру БД", 2)
        end

        conn:close()
    else
        message("Подключение к базе данных не удалось", 2)
    end
    env:close()
end

function OnStop()
    IsRun = false
end

function AddTrade(trade)
    if trade.class_code == CLASS_CODE then
        local t1 = copyFields(trade, foreach(Tables.trades, function(t) return t.name end))
        t1.datetime = os.time(t1.datetime)
        if trade.broker_comission == 0 then
            t1.broker_comission = BROKER_COMISSION * trade.qty
        end
        if (bit.test(trade.flags, 2)) then
            t1.qty = -t1.qty
        end

        Insert(conn, 'trades', t1)
    end
end

function GetTrades()
    ForEach("trades", AddTrade)
end

function OnTrade(t)
    AddTrade(t)
    message('OnTrade')
end
