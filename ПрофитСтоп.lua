dofile(getScriptPath() .. "\\tools.lua")
dofile(getScriptPath() .. "\\config.lua")
dofile(getScriptPath() .. "\\engine.lua")
setPrefix("PS")
IsRun = true

function main()
   local engines = {}

   while IsRun do
      if isConnected() then
         ForEach("futures_client_holding",
            function(t)
               if t.class_code == CLASS_CODE then
                  engines[t.sec_code] = engines[t.sec_code] or Engine:new(t.trdaccid, t.sec_code)
                  engines[t.sec_code]:Algo()
               end
            end
         )
      end
      sleep(1000)
   end
end

function OnStop()
   IsRun = false
end
