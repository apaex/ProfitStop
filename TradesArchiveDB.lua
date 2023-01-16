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
    { name = 'trade_num', type = "number" },
    { name = 'datetime', type = "table" },
    { name = 'order_num', type = "number" },
    { name = 'account', type = "string" },
    { name = 'sec_code', type = "string" },
    { name = 'class_code', type = "string" },
    { name = 'flags', type = "number" },
    { name = 'price', type = "number" },
    { name = 'qty', type = "number" },
    { name = 'value', type = "number" },
    { name = 'exchange_comission', type = "number" }
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



function AddTrade(t)
    if t.class_code == CLASS_CODE then
        Trades[t.trade_num] = copyFields(t, foreach(Fields, function (t) return t.name end))
        -- Trades[t.trade_num].datetime = os.time(Trades[t.trade_num].datetime)
        Changed = true;

        Insert(conn, 'trades', Trades[t.trade_num])
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
