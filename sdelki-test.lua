dofile(getScriptPath() .. "\\tools.lua")
dofile(getScriptPath() .. "\\qtools.lua")
dofile(getScriptPath() .. "\\sdelki.lua")
dofile(getScriptPath() .. "\\config.lua")
setPrefix("PS")
IsRun = true

function main()
    local sec_codes = {
        'RIH3',
        'MXH3',
        'SiH3',
        'BRG3',
      --  'NGF3',
        'GDH3'
    }
    for i, v in ipairs(sec_codes) do
        CalcStop('SPBFUTJRghl', v)
    end
end

function OnStop()
    IsRun = false
end
