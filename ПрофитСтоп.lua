dofile(getScriptPath() .. "\\tools.lua")
dofile(getScriptPath() .. "\\config.lua")
dofile(getScriptPath() .. "\\engine.lua")
setPrefix("PS")
IsRun = true

function main()

   if PROFIT_PER == 0 and STOP_PER == 0 then
      message('Вы не указали ни профит, ни стоп, бот "ПрофитСтоп" ОТКЛЮЧИЛСЯ !!!')
      return
   end

   local engines = {}

   while IsRun do
      if isConnected() then
         ForEach("futures_client_holding",
            function(t)
               if ACCOUNT == nil or t.trdaccid == ACCOUNT then
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
