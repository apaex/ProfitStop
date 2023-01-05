dofile(getScriptPath() .. "\\tools.lua")
dofile(getScriptPath() .. "\\config.lua")
dofile(getScriptPath() .. "\\engine.lua")
setPrefix("PS")
IsRun = true

engines = {}

function main()
   while IsRun do
      if isConnected() then
         ForEach("futures_client_holding",
            function(t)
               engines[t.sec_code] = engines[t.sec_code] or Engine:new(t.trdaccid, t.sec_code)
               engines[t.sec_code]:Algo()
            end
         )
      end
      sleep(1000)
   end
end

OnStop = function()
   IsRun = false
end
