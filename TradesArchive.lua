dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\qtools.lua")
dofile(getScriptPath() .. "\\src\\csv.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true
Changed = false;

Trades = {}


function main()
    local filename = getScriptPath() .. "\\trades.csv"
    local filename2 = getScriptPath() .. "\\trades2.csv"
    Trades = makeKey(LoadTableFromCSV(filename), "trade_num")
    Changed = true
    while IsRun do
        sleep(1000 * 1)
        if Changed then
            SaveTableToCSV(filename2, Trades)
            Changed = false
        end
    end

end

function OnStop()
    IsRun = false
end

function OnTrade(t)
    if class_code ~= CLASS_CODE then
        return
    end
    Trades[t.trade_num] =
    {
        trade_num = t.trade_num,
        datetime = t.datetime,
        order_num = t.order_num,
        account = t.account,
        sec_code = t.sec_code,
        class_code = t.class_code,
        flags = t.flags,
        price = t.price,
        qty = t.qty,
        value = t.value,
        exchange_comission = t.exchange_comission
    }
    Changed = true;

end
