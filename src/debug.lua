function setPrefix(prefix)
    PrintDbgStr_ = PrintDbgStr
    PrintDbgStr = function(v)
        if v == nil then
            message("PrintDbgStr(nil)", 2)
            PrintDbgStr_(prefix .. " " .. "PrintDbgStr(nil)")
        else
            PrintDbgStr_(prefix .. " " .. v)
        end
    end
    message_ = message
    message = function(v, l)
        message_(v, l)
        PrintDbgStr(v)
    end
end

function DebugWrite(v)
    if type(v) == "table" then
        for key, value in pairs(v) do
            PrintDbgStr(key .. " = (" .. type(value) .. ") " .. value)
        end
    else
        PrintDbgStr("(" .. type(v) .. ")" .. v)
    end
end

function printTable(name)
    n = getNumberOf(name)
    order = {}

    tablePrintDbgStr("TABLE " .. name .. "[" .. tostring(n) .. "]")

    for i = 0, n - 1 do
        order = getItem(name, i)
        tablePrintDbgStr(tostring(i) .. ":")
        tablePrintDbgStr(order)
    end
end
