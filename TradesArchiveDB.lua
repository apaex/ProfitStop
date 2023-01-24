sqlite3 = require "luasql.sqlite3"
dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\quik.lua")
dofile(getScriptPath() .. "\\src\\db_table.lua")
dofile(getScriptPath() .. "\\src\\db.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true

Trades = {}


function main()
    env  = sqlite3.sqlite3()
    DBTable.conn = env:connect(DB_FILE)
    if DBTable.conn then
        if db.trades:Create() then
            GetTrades()
            while IsRun do 
                sleep(1000)
                if #Trades > 0 then
                    message("Сохранение в БД")
                    SaveTrades()
                    message("/Сохранение в БД")
                end            
            end
        else
            message("Не удалось создать структуру БД", 2)
        end

        DBTable.conn:close()
    else
        message("Подключение к базе данных не удалось", 2)
    end
    env:close()
end

function OnStop()
    IsRun = false
end

function SaveTrades()
    foreach(Trades, function (t)
        db.trades:Insert(t)
        return nil
    end)
end


function AddTrade(trade)
    if trade.class_code == CLASS_CODE then
        local t1 = copyFields(trade, foreach(db.trades.fields, function(t) return t.name end))
        t1.datetime = os.time(t1.datetime)
        if trade.broker_comission == 0 then
            t1.broker_comission = BROKER_COMISSION * trade.qty
        end
        if (bit.test(trade.flags, 2)) then
            t1.qty = -t1.qty
        end

        Trades[trade.trade_num] = t1
    end
end

function GetTrades()
    ForEach("trades", AddTrade)
end

function OnTrade(t)
    AddTrade(t)
end
