sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\quik.lua")
dofile(getScriptPath() .. "\\src\\db.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true

Fields =
{
    { name = 'trade_num', type = "INTEGER" },
    { name = 'datetime', type = "DATATIME" },
    { name = 'account', type = "TEXT" },
    { name = 'class_code', type = "TEXT" },
    { name = 'sec_code', type = "TEXT" },
    { name = 'price', type = "REAL" },
    { name = 'qty', type = "INTEGER" },
    { name = 'value', type = "REAL" },
    { name = 'exchange_comission', type = "REAL" },
    { name = 'broker_comission', type = "REAL" },
    { name = 'order_num', type = "INTEGER" }
}

function main()
    env  = sqlite3.sqlite3()
    conn = env:connect(getScriptPath() .. "\\trades.sqlite")

    if not conn or not CreateTable(conn, 'trades', Fields, 'trade_num') or not CreateIndex(conn, 'trades', 'order_num') then
        message("Подключение к базе данных не удалось", 2)
        IsRun = false
    end

    if IsRun then
        GetTrades()
    end

    while IsRun do
    end

    if conn then
        conn:close()
    end
    env:close()
end

function OnStop()
    IsRun = false
end

function AddTrade(trade)
    if trade.class_code == CLASS_CODE then
        local t1 = copyFields(trade, foreach(Fields, function(t) return t.name end))
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
