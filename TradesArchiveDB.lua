sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\qtools.lua")
dofile(getScriptPath() .. "\\src\\dbtools.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true
Changed = false;

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

Trades = {}


function main()
    env  = sqlite3.sqlite3()
    conn = env:connect(getScriptPath() .. "\\trades.sqlite")

    if not conn or not CreateTable(conn, 'trades', Fields, 'trade_num') or not CreateIndex(conn, 'trades', 'order_num') then
        IsRun = false
    end


    GetTrades()


    Changed = true
    while IsRun do
        sleep(1000 * 1)
        if Changed then
            -- SaveTableToCSV(filename, Trades, Fields)
            Changed = false
        end
    end

    conn:close()
    env:close()
end

function OnStop()
    IsRun = false

end

function AddTrade(trade)
    if trade.class_code == CLASS_CODE then
        Trades[trade.trade_num] = copyFields(trade, foreach(Fields, function(t) return t.name end))
        Trades[trade.trade_num].datetime = os.time(Trades[trade.trade_num].datetime)
        if (bit.test(trade.flags, 2)) then
            Trades[trade.trade_num].qty = -Trades[trade.trade_num].qty
        end
        Insert(conn, 'trades', Trades[trade.trade_num])

        Changed = true;
    end
end

function GetTrades()
    ForEach("trades", function(t) AddTrade(t) end)
end

count = 1

function OnTrade(t)
    AddTrade(t)
    message(tostring(count))
    count = count + 1
end
