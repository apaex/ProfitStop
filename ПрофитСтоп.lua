dofile(getScriptPath() .. "\\src\\tools.lua")
dofile(getScriptPath() .. "\\src\\qtools.lua")
dofile(getScriptPath() .. "\\src\\config.lua")
dofile(getScriptPath() .. "\\src\\sdelki.lua")
dofile(getScriptPath() .. "\\src\\engine.lua")
dofile(getScriptPath() .. "\\src\\debug.lua")
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
               return not IsRun
            end
         )
      end
      sleep(1000)
   end

   message('Бот "ПрофитСтоп" ВЫКЛЮЧЕН !!!"')
end

function OnStop()
   IsRun = false
end
