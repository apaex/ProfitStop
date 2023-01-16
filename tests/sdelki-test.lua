dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\qtools.lua")
dofile(getScriptPath() .. "\\src\\sdelki.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
setPrefix("PS")
IsRun = true

function main()
    SaveToCSV("trades")
    local sec_codes = {
        'RIH3',
        'MXH3',
        'SiH3',
        'BRG3',
        'VBH3',
        'GDH3'
    }
    for i, v in ipairs(sec_codes) do
        CalcStop('SPBFUTJRghl', v)
    end
end

function OnStop()
    IsRun = false
end
