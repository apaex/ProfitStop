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
    { name = 'price', type = "INTEGER" },
    { name = 'qty', type = "INTEGER" },
    { name = 'value', type = "INTEGER" },
    { name = 'exchange_comission', type = "INTEGER" },
    { name = 'order_num', type = "INTEGER" }
}

function main()
    env  = sqlite3.sqlite3()
    conn = env:connect(getScriptPath() .. "\\trades.sqlite")

    if not conn or not CreateTable(conn, 'trades', Fields, 'trade_num') or not CreateIndex(conn, 'trades', 'order_num') then
        IsRun = false
    end

    GetTrades()

    conn:close()
    env:close()
end

function OnStop()
    IsRun = false
end

function AddTrade(trade)
    if trade.class_code == CLASS_CODE then
        local t1 = copyFields(trade, foreach(Fields, function(t) return t.name end))
        t1.datetime = os.time(t1.datetime)
        if (bit.test(trade.flags, 2)) then
            t1.qty = -t1.qty
        end
        Insert(conn, 'trades', t1)
    end
end

function GetTrades()
    ForEach("trades", function(t) AddTrade(t) end)
end

function OnTrade(t)
    AddTrade(t)
    message('OnTrade')
end
