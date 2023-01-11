dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\qtools.lua")
dofile(getScriptPath() .. "\\src\\csv.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true
Changed = false;

Fields =
{
    trade_num = "number",
    datetime = "number", -- С…СЂР°РЅРёРј РІ POSIX
    order_num = "number",
    account = "string",
    sec_code = "string",
    class_code = "string",
    flags = "number",
    price = "number",
    qty = "number",
    value = "number",
    exchange_comission = "number"
}

Trades = {}


function main()
    local filename = getScriptPath() .. "\\trades_db.csv"
    Trades = makeStructure(LoadTableFromCSV(filename), "trade_num", Fields)
    GetTrades()

    Changed = true
    while IsRun do
        sleep(1000 * 1)
        if Changed then
            SaveTableToCSV(filename, Trades, Fields)
            Changed = false
        end
    end

end

function OnStop()
    IsRun = false
end

function AddTrade(t)
    if t.class_code == CLASS_CODE then
        Trades[t.trade_num] = copyFields(t, Fields)
        Trades[t.trade_num].datetime = os.time(Trades[t.trade_num].datetime)
        Changed = true;
    end
end

function GetTrades()
    ForEach("trades", function(t) AddTrade(t) end)
end

function OnTrade(t)
    AddTrade(t)
end
