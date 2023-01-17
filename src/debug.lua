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
            if type(value) == "table" then
                PrintDbgStr(key .. " = (" .. type(value) .. ") " .. "[TABLE]")
            else
                PrintDbgStr(key .. " = (" .. type(value) .. ") " .. nz(value))
            end
        end
    else
        PrintDbgStr("(" .. type(v) .. ")" .. nz(v))
    end
end
