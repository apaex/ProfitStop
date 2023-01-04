---------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ --- QuikLuaCSharp.ru --------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
ACCOUNT              = 'SPBFUTJRghl'  -- Код счета
CLASS_CODE           = 'SPBFUT'         -- Код класса
-- SEC_CODE             = 'VBH3'          -- Код бумаги
-- STOP_SIZE            = 300              -- Размер стопа в минимальных шагах цены (если 0, ставится только профит)
-- PROFIT_SIZE          = 2000              -- Размер профита в минимальных шагах цены (если 0, ставится только стоп)
MOVE_STOP_BY_POS     = 0               -- Менять первоначальное положение стоп-заявки при изменении средней цены позиции добором (1 - да, 0 - нет)
LIMIT_KIND           = 0               -- Тип лимита (акции), для демо счета должно быть 0, для реального 2
BALANCE_TYPE         = 1               -- Тип отображения баланса в терминале Quik (1 - в лотах, 2 - с учетом количества в лоте)
                                       -- Например, при покупке 1 лота USDRUB одни брокеры в поле "Баланс" транслируют 1, другие 1000
                                       -- 1 лот акций Сбербанка может отображаться в таблице "Позиции по инструментам" в поле "Текущий остаток" как 1, или 10
EXPIRY_DATE          = 'GTC'           -- Срок действия стоп-заявки: 'TODAY' - до окончания текущей торговой сессии, 'GTC' -до отмены, или время в формате 'ГГГГММДД'
WORK_TIME            = {               -- Промежутки времени, когда бот работает (можно изменять/добавлять/удалять промежутки)
   [1] = {
      ['BEGIN']      = '9:00:05',     -- Сохранять значение начала работы на первом месте
      ['END']        = '13:59:55'
   },
   [2] = {
      ['BEGIN']      = '14:05:05',
      ['END']        = '18:44:50'
   },
   [3] = {
      ['BEGIN']      = '19:00:05',
      ['END']        = '23:54:50'      -- Сохранять значение конца работы на последнем месте
   }
}
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

RUN = true
trans_id = os.time()

WORK_TIME_sec = {}
SDT_sec = 0
LastDay = 0

Engine = {}
engines = {}

main = function()	
   local params = {
      "GDH3",
      "SiH3",
      "EuU3",
      "CRH3",
      "MXH3",
      "RIH3",
      "NGF3",
      "BRG3"
   }
   for i, v in ipairs(params) do
      engines[v] = Engine:new(v)
	end
--   if self.STOP_SIZE == 0 and self.PROFIT_SIZE == 0 then
--      message(self.SEC_CODE..' Вы не указали ни профит, ни стоп, бот "ПрофитСтоп" ОТКЛЮЧИЛСЯ !!!')
--      return
--   end
   
   -- Цикл по дням
   while RUN do
      -- Ждет нового дня
      while RUN and (isConnected() == 0 or GetServerDateTime().day == LastDay) do sleep(100) end
      if not RUN then return end
      
      -- Получает временные промежутки дня
      WORK_TIME_sec = {}
      for i=1,#WORK_TIME do
         WORK_TIME_sec[i] = {
            ['BEGIN'] = os.time(StrToTime(WORK_TIME[i].BEGIN)),
            ['END'] = os.time(StrToTime(WORK_TIME[i].END)),
         }
      end
      -- Ждет начала первого торгового периода
      while RUN and os.time(GetServerDateTime()) < WORK_TIME_sec[1].BEGIN do sleep(100) end
      if not RUN then return end
            
      -- Цикл внутри дня
      local may_work = false
      while RUN do
         SDT_sec = os.time(GetServerDateTime())
         may_work = false
         for i=1,#WORK_TIME_sec do
            if (SDT_sec >= WORK_TIME_sec[i].BEGIN and SDT_sec < WORK_TIME_sec[i].END) then
               may_work = true
            end
         end
         if may_work then
            for key, v in pairs(engines) do
               v:Algo()
            end
         else
            -- Если день закончился
            if SDT_sec >= WORK_TIME_sec[#WORK_TIME_sec].END then
               LastDay = GetServerDateTime().day
               -- Ждет следующего
               break
            end
         end
         sleep(1)
      end
   end
end

OnStop = function()
   RUN = false
end


function Engine:new(SEC_CODE)
   newObj = {}
 
   newObj.SEC_CODE             = SEC_CODE         -- Код бумаги
   newObj.STOP_SIZE            = 300              -- Размер стопа в минимальных шагах цены (если 0, ставится только профит)
   newObj.PROFIT_SIZE          = 2000              -- Размер профита в минимальных шагах цены (если 0, ставится только стоп)

   -- Получает минимальный шаг цены инструмента
   newObj.PriceStep = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value)

   newObj.StopOrderNum = nil
   newObj.StopPos = 0
   newObj._STOP_SIZE = newObj.STOP_SIZE
   newObj._PROFIT_SIZE = newObj.PROFIT_SIZE
   newObj.NeedSetToOldPricesLevels = false

   self.__index = self
   return setmetatable(newObj, self)
end

function Engine:Algo()
   local totalnet = self:GetTotalnet()
   -- Есть позиция
   if totalnet ~= 0 then
      -- Стоп не соответствует (размер позиции изменился)
      if self.StopPos ~= -totalnet then
         -- Есть стоп-заявка бота
         if self.StopOrderNum ~= nil then
            -- Если активна
            if self:CheckStopOrderActive(self.StopOrderNum) then
               -- Снимает
               self:Kill_SO(self.StopOrderNum)
               -- Запоминает, что нужно перевыставить стоп-заявку в те же цены
               if MOVE_STOP_BY_POS == 0 and ((self.StopPos > 0 and totalnet < 0) or (self.StopPos < 0 and totalnet > 0)) then NeedSetToOldPricesLevels = true end
            end
         -- Нет стоп заявки бота
         else
            -- Ищет стоп-заявку пользователя
            self:FindUserStopOrder()
            -- Снимает все стоп-заявки по инструменту, если есть
            self:KillAll_SO()
         end
         -- Снова получает размер позиции на случай, если стоп-заявка успела исполниться до снятия
         totalnet = self:GetTotalnet()
         -- Позиция осталась
         if totalnet ~= 0 then
            -- Получает цену текущей позиции
            local pos_price = self:GetPosPrice()
            -- Получает количество лотов без знака в заявке
            local qty = math.floor(math.abs(totalnet))
            -- Определяет направление стоп-заявки и запоминает изменение позиции стоп-заявкой
            local operation = 'S'
            self.StopPos = -qty
            if totalnet < 0 then
               operation = 'B'
               self.StopPos = qty
            end
            -- Если нужно выставить стоп и профит
            if self.STOP_SIZE ~= 0 and self.PROFIT_SIZE ~= 0 then
               -- Если нужно выставить в обычном режиме
               if not NeedSetToOldPricesLevels then
                  -- Выставляет "Тейк профит и Стоп лимит" заявку
                  self:SetTP_SL(
                     operation,     -- Операция ('B', или 'S')
                     pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
                     qty,           -- Количество лотов
                     self.PROFIT_SIZE,   -- Размер профита в шагах цены
                     self.STOP_SIZE      -- Размер стопа в шагах цены
                  )
               -- Нужно выставить в те же цены
               else
                  -- Получает цены из снятой стоп-заявки
                  local profit_price, stop_price = self:GetStopOrderPrices(self.StopOrderNum)
                  local profit_size = 0
                  local stop_size = 0
                  if totalnet > 0 then
                     profit_size = math.floor(math_round((profit_price - pos_price)/self.PriceStep))
                     stop_size = math.floor(math_round((pos_price - stop_price)/self.PriceStep))
                  else
                     profit_size = math.floor(math_round((pos_price - profit_price)/self.PriceStep))
                     stop_size = math.floor(math_round((stop_price - pos_price)/self.PriceStep))
                  end
                  -- Выставляет "Тейк профит и Стоп лимит" заявку
                  self:SetTP_SL(
                     operation,     -- Операция ('B', или 'S')
                     pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
                     qty,           -- Количество лотов
                     profit_size,   -- Размер профита в шагах цены
                     stop_size      -- Размер стопа в шагах цены
                  )
               end
            -- Нужно выставить только стоп
            elseif self.PROFIT_SIZE == 0 then
               local stop_price = 0
               -- Если нужно выставить в обычном режиме
               if not NeedSetToOldPricesLevels then
                  if totalnet < 0 then
                     stop_price = pos_price + self.STOP_SIZE*self.PriceStep
                  else
                     stop_price = pos_price - self.STOP_SIZE*self.PriceStep
                  end
               -- Нужно выставить в те же цены
               else
                  -- Получает цены из снятой стоп-заявки
                  _, stop_price = self:GetStopOrderPrices(self.StopOrderNum)
               end
               -- Выставляет стоп-заявку
               self:Set_SL(
                  operation,
                  stop_price,
                  qty
               )
            -- Нужно выставить только профит
            elseif self.STOP_SIZE == 0 then
               -- Если нужно выставить в обычном режиме
               if not NeedSetToOldPricesLevels then
                  -- Выставляет "Тейк профит" заявку
                  self:SetTP(
                     operation,     -- Операция ('B', или 'S')
                     pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
                     qty,           -- Количество лотов
                     self.PROFIT_SIZE    -- Размер профита в шагах цены
                  )
               -- Нужно выставить в те же цены
               else
                  -- Получает цены из снятой стоп-заявки
                  local profit_price, _ = self:GetStopOrderPrices(self.StopOrderNum)
                  local profit_size = 0
                  if totalnet > 0 then
                     profit_size = math.floor(math_round((profit_price - pos_price)/self.PriceStep))
                  else
                     profit_size = math.floor(math_round((pos_price - profit_price)/self.PriceStep))
                  end
                  -- Выставляет "Тейк профит" заявку
                  self:SetTP(
                     operation,     -- Операция ('B', или 'S')
                     pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
                     qty,           -- Количество лотов
                     profit_size    -- Размер профита в шагах цены
                  )
               end
            end
            
            -- Если робот аварийно завршил работу, выходит из функции
            if not RUN then return end
            
            -- Запоминает номер стоп-заявки
            self.StopOrderNum = self:GetStopOrderNum(trans_id)
         end
      -- Стоп соответствует
      else
         -- Стоп-заявка снята (пользователь изменил стоп-заявку)
         if self:CheckStopOrderKilled(self.StopOrderNum) then
            -- Ищет измененную стоп-заявку
            local newStopOrderNum = self:GetActiveStopOrderNumByComment('AS') 
            if newStopOrderNum ~= nil then self.StopOrderNum = newStopOrderNum end
         -- Стоп-заявка исполнилась
         elseif self:CheckStopOrderCompleted(self.StopOrderNum) then
            -- Ничего не делает
         end
      end
   -- Нет позиции
   else      
      -- Есть стоп-заявка бота
      if self.StopOrderNum ~= nil then
         -- Если активна
         if self:CheckStopOrderActive(self.StopOrderNum) then
            -- Снимает
            self:Kill_SO(self.StopOrderNum)
         end
         self.StopOrderNum = nil
         self.StopPos = 0
      end
      -- Возвращает установленные изначально значения 
      self.STOP_SIZE = self._STOP_SIZE
      self.PROFIT_SIZE = self._PROFIT_SIZE
      NeedSetToOldPricesLevels = false
   end
end

-- Получает цену текущей позиции
function Engine:GetPosPrice()
   -- Акции
   if CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
      -- Перебирает таблицу "Позиции по инструментам"
      local num = getNumberOf('depo_limits')
      local depo_limit = nil
      for i=0,num-1 do
         depo_limit = getItem('depo_limits', i)
         if depo_limit.sec_code == self.SEC_CODE
         and depo_limit.trdaccid == ACCOUNT
         and depo_limit.limit_kind == LIMIT_KIND then 
            return depo_limit.awg_position_price
         end
      end
   -- Фьючерсы, опционы
   elseif CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
      local totalnet = self:GetTotalnet()
      -- Если позиция есть
      if totalnet ~= 0 then
         local abs_totalnet = math.abs(totalnet)
         local sum = 0
         local sum_lots = 0
         local trade = nil
         -- Перебирает сделки
         local num = getNumberOf('trades')
         for i=num-1,0,-1 do
            trade = getItem('trades', i)
            if trade.sec_code == self.SEC_CODE then
               if (totalnet < 0 and bit.test(trade.flags, 2)) or (totalnet > 0 and not bit.test(trade.flags, 2)) or totalnet == 0 then
                  sum = sum + trade.price*trade.qty
                  sum_lots = sum_lots + trade.qty
                  -- Если найдены все сделки набора позиции
                  if sum_lots >= abs_totalnet then
                     -- Возвращает среднюю цену
                     message('ddd '..totalnet)
                     return sum/sum_lots                     
                  end
               end
            end
         end
         -- Не удалось найти все сделки набора позиции
         -- Если найдены хоть какие-то сделки набора
         if sum_lots > 0 then
            -- Возвращает среднюю цену найденных
            return sum/sum_lots
         -- Сделок набора не найдено
         else
            -- Возвращает эффективную цену позиции
            local num = getNumberOf('futures_client_holding')
            if num > 0 then
               -- Находит размер лота
               local lot = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LOTSIZE').param_value)
               local futures_client_holding = nil
               if num > 1 then
                  for i = 0, num - 1 do
                     futures_client_holding = getItem('futures_client_holding', i)
                     if futures_client_holding.sec_code == self.SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
                        return futures_client_holding.avrposnprice
                     end
                  end
               else
                  futures_client_holding = getItem('futures_client_holding', 0)
                  if futures_client_holding.sec_code == self.SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
                     return futures_client_holding.avrposnprice
                  end
               end
            end
         end
      end
   end
   
   -- Если не удалось получить значение, возвращает цену последней сделки по инструменту
   return tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LAST').param_value)
end

-- Получает текущую чистую позицию по инструменту
function Engine:GetTotalnet()
   -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
   if CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
      local num = getNumberOf('futures_client_holding')
      if num > 0 then
         -- Находит размер лота
         local lot = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LOTSIZE').param_value)
         if num > 1 then
            for i = 0, num - 1 do
               local futures_client_holding = getItem('futures_client_holding',i)
               if futures_client_holding.sec_code == self.SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
                  if BALANCE_TYPE == 1 then
                     return futures_client_holding.totalnet
                  else
                     return futures_client_holding.totalnet/lot
                  end
               end
            end
         else
            local futures_client_holding = getItem('futures_client_holding',0)
            if futures_client_holding.sec_code == self.SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
               if BALANCE_TYPE == 1 then
                  return futures_client_holding.totalnet
               else
                  return futures_client_holding.totalnet/lot
      end
            end
         end
      end
   -- АКЦИИ
   elseif CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
      local num = getNumberOf('depo_limits')
      if num > 0 then
         local lot = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LOTSIZE').param_value)
         if num > 1 then
            for i = 0, num - 1 do
               local depo_limit = getItem('depo_limits', i)
               if depo_limit.sec_code == self.SEC_CODE
               and depo_limit.trdaccid == ACCOUNT
               and depo_limit.limit_kind == LIMIT_KIND then 
                  if BALANCE_TYPE == 1 then
                     return depo_limit.currentbal
                  else
                     return depo_limit.currentbal/lot
                  end
               end
            end
         else
            local depo_limit = getItem('depo_limits', 0)
            if depo_limit.sec_code == self.SEC_CODE
            and depo_limit.trdaccid == ACCOUNT
            and depo_limit.limit_kind == LIMIT_KIND then 
               if BALANCE_TYPE == 1 then
                  return depo_limit.currentbal
               else
                  return depo_limit.currentbal/lot
               end
            end
         end
      end
   -- ВАЛЮТА
   elseif CLASS_CODE == 'CETS' then
      local num = getNumberOf('money_limits')
      if num > 0 then
         -- Находит валюту
         local cur = string.sub(self.SEC_CODE, 1, 3)
         local lot = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LOTSIZE').param_value)
         if num > 1 then
            for i = 0, num - 1 do
               local money_limit = getItem('money_limits', i)
               if money_limit.currcode == cur
               and money_limit.client_code == CLIENT_CODE
               and money_limit.limit_kind == LIMIT_KIND then 
                  if BALANCE_TYPE == 1 then
                     return money_limit.currentbal
                  else
                     return money_limit.currentbal/lot
                  end
               end
            end
         else
            local money_limit = getItem('money_limits', 0)
            if money_limit.currcode == cur
            and money_limit.client_code == CLIENT_CODE
            and money_limit.limit_kind == LIMIT_KIND then 
               if BALANCE_TYPE == 1 then
                  return money_limit.currentbal
               else
                  return money_limit.currentbal/lot
               end
            end
         end
      end
   end
 
   -- Если позиция по инструменту в таблице не найдена, возвращает 0
   return 0
end

-- Ищет стоп-заявку пользователя
function Engine:FindUserStopOrder()
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если заявка активна
      if stop_order.sec_code == self.SEC_CODE and bit.test(stop_order.flags, 0) then
         -- Получает параметры стоп-заявки
         self.StopOrderNum = stop_order.order_num
         local totalnet = self:GetTotalnet()
         -- ЛОНГ
         if totalnet > 0 then
            -- Тейк-профит
            if stop_order.stop_order_type == 6 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep 
               self.STOP_SIZE = 0
            -- тейк-профит и стоп-лимит 
            elseif stop_order.stop_order_type == 9 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep
               -- Вычисляет размер стопа
               self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price2)/self.PriceStep
            -- стоп-лимит 
            elseif stop_order.stop_order_type == 1 then
               self.PROFIT_SIZE = 0
               -- Вычисляет размер стопа
               self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep
            end
         -- ШОРТ
         else
            -- Тейк-профит
            if stop_order.stop_order_type == 6 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep 
               self.STOP_SIZE = 0
            -- тейк-профит и стоп-лимит 
            elseif stop_order.stop_order_type == 9 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep
               -- Вычисляет размер стопа
               self.STOP_SIZE = (stop_order.condition_price2 - self:GetPosPrice())/self.PriceStep
            -- стоп-лимит 
            elseif stop_order.stop_order_type == 1 then
               self.PROFIT_SIZE = 0
               -- Вычисляет размер стопа
               self.STOP_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep
            end
         end
         break
      end
   end
end

-- Получает цены из стоп-заявки (profit_price, stop_price)
function Engine:GetStopOrderPrices(order_num)
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если нужная стоп-заявка
      if stop_order.order_num == order_num then
         -- Тейк-профит
         if stop_order.stop_order_type == 6 then
            return stop_order.condition_price, stop_order.condition_price
         -- тейк-профит и стоп-лимит 
         elseif stop_order.stop_order_type == 9 then
            return stop_order.condition_price, stop_order.condition_price2
         -- стоп-лимит 
         elseif stop_order.stop_order_type == 1 then
            return stop_order.condition_price, stop_order.condition_price
         end
      end
   end
end

-- Выставляет стоп-лимит заявку
function Engine:Set_SL(
   operation,     -- Операция ('B' - buy, 'S' - sell)
   stop_price,    -- Цена Стоп-Лосса
   qty            -- Количество в лотах
)
   -- Получает ID для следующей транзакции
   trans_id = trans_id + 1
   -- Вычисляет цену, по которой выставится заявка при срабатывании стопа
   local price = stop_price - 50*self.PriceStep
   if operation == 'B' then price = stop_price + 50*self.PriceStep end
   -- Заполняет структуру для отправки транзакции на Стоп-лосс
   local T = {}
   T['TRANS_ID']           = tostring(trans_id)
   T['CLASSCODE']          = CLASS_CODE
   T['SECCODE']            = self.SEC_CODE
   T['ACCOUNT']            = ACCOUNT
   T['ACTION']             = 'NEW_STOP_ORDER'               -- Тип заявки      
   T['OPERATION']          = operation                      -- Операция ('B' - покупка(BUY), 'S' - продажа(SELL))
   T['QUANTITY']           = tostring(qty)                  -- Количество в лотах
   T['STOPPRICE']          = self:GetCorrectPrice(stop_price)    -- Цена Стоп-Лосса
   T['PRICE']              = self:GetCorrectPrice(price)         -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
   T['EXPIRY_DATE']        = EXPIRY_DATE                    -- 'TODAY', 'GTC', или время
   T['CLIENT_CODE']        = 'AS'                           -- Комментарий
 
   -- Отправляет транзакцию
   local Res = sendTransaction(T)
   -- Если при отправке транзакции возникла ошибка
   if Res ~= '' then
      -- Выводит ошибку
      message(self.SEC_CODE..' Ошибка транзакции стоп-лимит: '..Res)
      message(self.SEC_CODE..' Бот "ПрофитСтоп" ВЫКЛЮЧЕН !!!"')
      OnStop()
   end
end
-- Выставляет "Тейк профит" заявку
function Engine:SetTP(
   operation,     -- Операция ('B', или 'S')
   pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
   qty,           -- Количество лотов
   profit_size    -- Размер профита в шагах цены
)
   -- Получает ID для следующей транзакции
   trans_id = trans_id + 1
   -- Получает минимальный шаг цены
   -- local self.PriceStep = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, "SEC_PRICE_STEP").param_value)
   -- Получает максимально возможную цену заявки
   local PriceMax = tonumber(getParamEx(CLASS_CODE,  self.SEC_CODE, 'PRICEMAX').param_value)
   -- Получает минимально возможную цену заявки
   local PriceMin = tonumber(getParamEx(CLASS_CODE,  self.SEC_CODE, 'PRICEMIN').param_value)
   -- Заполняет структуру для отправки транзакции на Стоп-лосс и Тэйк-профит
   local T = {}
   T['TRANS_ID']              = tostring(trans_id)
   T['CLASSCODE']             = CLASS_CODE
   T['SECCODE']               = self.SEC_CODE
   T['ACCOUNT']               = ACCOUNT
   T['ACTION']                = 'NEW_STOP_ORDER'                                    -- Тип заявки      
   T['STOP_ORDER_KIND']       = 'TAKE_PROFIT_STOP_ORDER'                            -- Тип стоп-заявки
   T['OPERATION']             = operation                                           -- Операция ('B' - покупка(BUY), 'S' - продажа(SELL))   
   T['QUANTITY']              = tostring(qty)                                       -- Количество в лотах
 
   -- Вычисляет цену профита
   local stopprice = 0
   if operation == 'B' then
      stopprice = pos_price - profit_size*self.PriceStep
      if PriceMin ~= nil and PriceMin ~= 0 and stopprice < PriceMin then
         stopprice = PriceMin
      end
   elseif operation == 'S' then
      stopprice = pos_price + profit_size*self.PriceStep
      if PriceMax ~= nil and PriceMax ~= 0 and stopprice > PriceMax then
         stopprice = PriceMax
      end
   end
   T['STOPPRICE']             = self:GetCorrectPrice(stopprice)                          -- Цена Тэйк-Профита
   T['OFFSET']                = '0'                                                 -- отступ
   T['OFFSET_UNITS']          = 'PRICE_UNITS'                                       -- в шагах цены
   local spread = 50*self.PriceStep
   if operation == 'B' then
      if PriceMax ~= nil and PriceMax ~= 0 and stopprice + spread > PriceMax then
         spread = PriceMax - stopprice - 1*self.PriceStep
      end
   elseif operation == 'S' then
      if PriceMin ~= nil and PriceMin ~= 0 and stopprice - spread < PriceMin then
         spread = stopprice - PriceMin - 1*self.PriceStep
      end
   end
   T['SPREAD']                = self:GetCorrectPrice(spread)                             -- Защитный спред
   T['SPREAD_UNITS']          = 'PRICE_UNITS'                                       -- в шагах цены
 
   T['EXPIRY_DATE']           = EXPIRY_DATE                                         -- 'TODAY', 'GTC', или время
   T['CLIENT_CODE']           = 'AS'                                                -- Комментарий
 
   -- Отправляет транзакцию
   local Res = sendTransaction(T)
   if Res ~= '' then
      message(self.SEC_CODE..' Ошибка выставления стоп-заявки: '..Res)
      message(self.SEC_CODE..' Бот "ПрофитСтоп" ВЫКЛЮЧЕН !!!"')
      OnStop()
   end
end
-- Выставляет "Тейк профит и Стоп лимит" заявку
function Engine:SetTP_SL(
   operation,     -- Операция ('B', или 'S')
   pos_price,     -- Цена позиции, на которую выставляется стоп-заявка
   qty,           -- Количество лотов
   profit_size,   -- Размер профита в шагах цены
   stop_size      -- Размер стопа в шагах цены
)
   -- Получает минимальный шаг цены
   -- local self.PriceStep = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, "SEC_PRICE_STEP").param_value)
   -- Получает максимально возможную цену заявки
   local PriceMax = tonumber(getParamEx(CLASS_CODE,  self.SEC_CODE, 'PRICEMAX').param_value)
   -- Получает минимально возможную цену заявки
   local PriceMin = tonumber(getParamEx(CLASS_CODE,  self.SEC_CODE, 'PRICEMIN').param_value)
   -- Заполняет структуру для отправки транзакции на Стоп-лосс и Тэйк-профит
   local T = {}
   T['TRANS_ID']              = tostring(trans_id)
   T['CLASSCODE']             = CLASS_CODE
   T['SECCODE']               = self.SEC_CODE
   T['ACCOUNT']               = ACCOUNT
   T['ACTION']                = 'NEW_STOP_ORDER'                                    -- Тип заявки      
   T['STOP_ORDER_KIND']       = 'TAKE_PROFIT_AND_STOP_LIMIT_ORDER'                  -- Тип стоп-заявки
   T['OPERATION']             = operation                                           -- Операция ('B' - покупка(BUY), 'S' - продажа(SELL))   
   T['QUANTITY']              = tostring(qty)                                       -- Количество в лотах
   T['TYPE']				  = 'M'
 
   -- Вычисляет цену профита
   local stopprice = 0
   if operation == 'B' then
      stopprice = pos_price - profit_size*self.PriceStep
      if PriceMin ~= nil and PriceMin ~= 0 and stopprice < PriceMin then
         stopprice = PriceMin
      end
   elseif operation == 'S' then
      stopprice = pos_price + profit_size*self.PriceStep
      if PriceMax ~= nil and PriceMax ~= 0 and stopprice > PriceMax then
         stopprice = PriceMax
      end
   end
   T['STOPPRICE']             = self:GetCorrectPrice(stopprice)                          -- Цена Тэйк-Профита
   T['OFFSET']                = '0'                                                 -- отступ
   T['OFFSET_UNITS']          = 'PRICE_UNITS'                                       -- в шагах цены
   local spread = 50*self.PriceStep
   if operation == 'B' then
      if PriceMax ~= nil and PriceMax ~= 0 and stopprice + spread > PriceMax then
         spread = PriceMax - stopprice - 1*self.PriceStep
      end
   elseif operation == 'S' then
      if PriceMin ~= nil and PriceMin ~= 0 and stopprice - spread < PriceMin then
         spread = stopprice - PriceMin - 1*self.PriceStep
      end
   end
   T['SPREAD']                = self:GetCorrectPrice(spread)                             -- Защитный спред
   T['SPREAD_UNITS']          = 'PRICE_UNITS'                                       -- в шагах цены
   T['MARKET_TAKE_PROFIT']    = 'YES'                                                -- 'YES', или 'NO'
 
   -- Вычисляет цену стопа
   local stopprice2 = 0
   if operation == 'B' then
      stopprice2 = pos_price + stop_size*self.PriceStep
      if PriceMax ~= nil and PriceMax ~= 0 and stopprice2 > PriceMax then
         stopprice2 = PriceMax
      end
   elseif operation == 'S' then
      stopprice2 = pos_price - stop_size*self.PriceStep
      if PriceMin ~= nil and PriceMin ~= 0 and stopprice2 < PriceMin then
         stopprice2 = PriceMin
      end
   end
   T['STOPPRICE2']            = self:GetCorrectPrice(stopprice2)                         -- Цена Стоп-Лосса
   -- Вычисляет цену, по которой выставится заявка при срабатывании стопа
   local price = 0
   if operation == 'B' then
      price = stopprice2 + 50*self.PriceStep
      if PriceMax ~= nil and PriceMax ~= 0 and price > PriceMax then
         price = PriceMax
      end
   elseif operation == 'S' then
      price = stopprice2 - 50*self.PriceStep
      if PriceMin ~= nil and PriceMin ~= 0 and price < PriceMin then
         price = PriceMin
      end
   end
   T['PRICE']                 = self:GetCorrectPrice(price)                              -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
   T['MARKET_STOP_LIMIT']     = 'YES'                                                -- 'YES', или 'NO'
   T['EXPIRY_DATE']           = EXPIRY_DATE                                         -- 'TODAY', 'GTC', или время
   T['IS_ACTIVE_IN_TIME']     = 'NO'                                                -- Признак действия заявки типа «Тэйк-профит и стоп-лимит» в течение определенного интервала времени. Значения «YES» или «NO»
   T['CLIENT_CODE']           = 'AS'                                                -- Комментарий
   
   -- Отправляет транзакцию
   local Res = sendTransaction(T)
   if Res ~= '' then
      message(self.SEC_CODE..' Ошибка выставления стоп-заявки: '..Res)
      message(self.SEC_CODE..' Бот "ПрофитСтоп" ВЫКЛЮЧЕН !!!"')
      OnStop()
   end
end

-- Возвращает номер активной стоп-заявки с соответствующим комментарием, либо nil
function Engine:GetActiveStopOrderNumByComment(comment)
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если заявка активна и комментарий совпадает
      if bit.test(stop_order.flags, 0) and stop_order.brokerref:find(comment) ~= nil then
         -- Получает параметры стоп-заявки
         local totalnet = self:GetTotalnet()
         -- ЛОНГ
         if totalnet > 0 then
            -- Тейк-профит
            if stop_order.stop_order_type == 6 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep 
            -- тейк-профит и стоп-лимит 
            elseif stop_order.stop_order_type == 9 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep
               -- Вычисляет размер стопа
               self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price2)/self.PriceStep
            -- стоп-лимит 
            elseif stop_order.stop_order_type == 1 then
               -- Вычисляет размер стопа
               self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep
            end
         -- ШОРТ
         else
            -- Тейк-профит
            if stop_order.stop_order_type == 6 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep 
            -- тейк-профит и стоп-лимит 
            elseif stop_order.stop_order_type == 9 then
               -- Вычисляет размер профита
               self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price)/self.PriceStep
               -- Вычисляет размер стопа
               self.STOP_SIZE = (stop_order.condition_price2 - self:GetPosPrice())/self.PriceStep
            -- стоп-лимит 
            elseif stop_order.stop_order_type == 1 then
               -- Вычисляет размер стопа
               self.STOP_SIZE = (stop_order.condition_price - self:GetPosPrice())/self.PriceStep
            end
         end
         -- Возвращает номер стоп-заявки
         return stop_order.order_num
      end
   end
   
   return nil
end
-- Возвращает номер стоп-заявки по ее ID транзакции
function Engine:GetStopOrderNum(id)
   while RUN do
      -- Перебирает таблицу стоп-заявок от последней к первой
      for i=getNumberOf('stop_orders') - 1, 0, -1 do
         -- Получает стоп-заявку из строки таблицы с индексом i
         local stop_order = getItem('stop_orders', i)
         -- Если ID транзакции совпадает
         if stop_order.trans_id == id then
            -- Возвращает номер стоп-заявки
            return stop_order.order_num
         end
      end
      sleep(10)
   end
end
-- Проверяет по номеру активна ли стоп-заявка 
function Engine:CheckStopOrderActive(order_num)
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если номер транзакции совпадает
      if stop_order.order_num == order_num then
         -- Если стоп-заявка активна
         if bit.test(stop_order.flags, 0) then
            return true
         else
            return false
         end
      end
   end
end
-- Проверяет по номеру снята ли стоп-заявка 
function Engine:CheckStopOrderKilled(order_num)
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если номер транзакции совпадает
      if stop_order.order_num == order_num then
         -- Если стоп-заявка снята
         if bit.test(stop_order.flags, 1) then
            return true
         else
            return false
         end
      end
   end
end
-- Проверяет по номеру исполнена ли стоп-заявка 
function Engine:CheckStopOrderCompleted(order_num)
   -- Перебирает таблицу стоп-заявок от последней к первой
   for i=getNumberOf('stop_orders') - 1, 0, -1 do
      -- Получает стоп-заявку из строки таблицы с индексом i
      local stop_order = getItem('stop_orders', i)
      -- Если номер транзакции совпадает
      if stop_order.order_num == order_num then
         -- Если стоп-заявка исполнена
         if not bit.test(stop_order.flags, 0) and not bit.test(stop_order.flags, 1) then
            return true
         else
            return false
         end
      end
   end
end
-- Снимает стоп-заявку
function Engine:Kill_SO(
   stop_order_num    -- Номер снимаемой стоп-заявки
)
   -- Находит стоп-заявку (30 сек. макс.)
   local index = 0
   local start_sec = os.time()
   local find_so = false
   while RUN and not find_so and os.time() - start_sec < 30 do
      for i=getNumberOf('stop_orders')-1,0,-1 do
         local stop_order = getItem('stop_orders', i)
         if stop_order.order_num == stop_order_num then
            -- Если стоп-заявка уже была исполнена (не активна)
            if not bit.test(stop_order.flags, 0) then
               return false
            end
            index = i
            find_so = true
            break
         end
      end
   end
   if not find_so then
      message(self.SEC_CODE..' Ошибка: не найдена стоп-заявка!')
      return false
   end
 
   -- Получает ID для следующей транзакции
   trans_id = trans_id + 1
   -- Заполняет структуру для отправки транзакции на снятие стоп-заявки
   local T = {}
   T['TRANS_ID']            = tostring(trans_id)
   T['CLASSCODE']           = CLASS_CODE
   T['SECCODE']             = self.SEC_CODE
   T['ACTION']              = 'KILL_STOP_ORDER'        -- Тип заявки 
   T['STOP_ORDER_KEY']      = tostring(stop_order_num) -- Номер стоп-заявки, снимаемой из торговой системы
 
   -- Отправляет транзакцию
   local Res = sendTransaction(T)
   -- Если при отправке транзакции возникла ошибка
   if Res ~= '' then
      -- Выводит ошибку
      message(self.SEC_CODE..' Ошибка снятия стоп-заявки: '..Res)
      return false
   end   
 
   -- Ожидает когда стоп-заявка перестанет быть активна (30 сек. макс.)
   start_sec = os.time()
   local active = true
   while RUN and os.time() - start_sec < 30 do
      local stop_order = getItem('stop_orders', index)
      -- Если стоп-заявка не активна
      if not bit.test(stop_order.flags, 0) then
         -- Если стоп-заявка успела исполниться
         if not bit.test(stop_order.flags, 1) then
            return false
         end
         active = false
         break
      end
      sleep(10)
   end
   if active then
      message(self.SEC_CODE..' Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
      return false
   end
 
   return true
end
-- Снимает все стоп-заявки по инструменту
function Engine:KillAll_SO()
   for i=getNumberOf('stop_orders')-1,0,-1 do
      local stop_order = getItem('stop_orders', i)
      -- Найдена активная заявка по инструменту
      if stop_order.sec_code == self.SEC_CODE and bit.test(stop_order.flags, 0) then
         -- Снимает
         self:Kill_SO(stop_order.order_num)
      end
   end
end

-- Приводит переданную цену к требуемому для транзакции по инструменту виду
function Engine:GetCorrectPrice(price) -- STRING
   -- Получает точность цены по инструменту
   local scale = getSecurityInfo(CLASS_CODE, self.SEC_CODE).scale
   -- Получает минимальный шаг цены инструмента
   -- local PriceStep = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, "SEC_PRICE_STEP").param_value)
   -- Если после запятой должны быть цифры
   if scale > 0 then
      price = tostring(price)
      -- Ищет в числе позицию запятой, или точки
      local dot_pos = price:find('.')
      local comma_pos = price:find(',')
      -- Если передано целое число
      if dot_pos == nil and comma_pos == nil then
         -- Добавляет к числу ',' и необходимое количество нулей и возвращает результат
         price = price..','
         for i=1,scale do price = price..'0' end
         return price
      else -- передано вещественное число         
         -- Если нужно, заменяет запятую на точку 
         if comma_pos ~= nil then price:gsub(',', '.') end
         -- Округляет число до необходимого количества знаков после запятой
         price = math_round(tonumber(price), scale)
         -- Корректирует на соответствие шагу цены
         price = math_round(price/self.PriceStep)*self.PriceStep
         price = string.gsub(tostring(price),'[%.]+', ',')
         return price
      end
   else -- После запятой не должно быть цифр
      -- Корректирует на соответствие шагу цены
      price = math_round(price/self.PriceStep)*self.PriceStep
      return tostring(math.floor(price))
   end
end

-- Округляет число до указанной точности
math_round = function(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

UpdateDataSecQty     = 10              -- Количество секунд ожидания подгрузки данных с сервера после возобновления подключения
-- Ждет подключения к серверу, после чего ждет еще UpdateDataSecQty секунд подгрузки пропущенных данных с сервера
WaitUpdateDataAfterReconnect = function()
   while RUN and isConnected() == 0 do sleep(100) end
   if RUN then sleep(UpdateDataSecQty * 1000) end
   -- Повторяет операцию если соединение снова оказалось разорвано
   if RUN and isConnected() == 0 then WaitUpdateDataAfterReconnect() end
end
-- Возвращает текущую дату/время сервера в виде таблицы datetime
GetServerDateTime = function()
   local dt = {}
 
   -- Пытается получить дату/время сервера
   while RUN and dt.day == nil do
      dt.day,dt.month,dt.year,dt.hour,dt.min,dt.sec = string.match(getInfoParam('TRADEDATE')..' '..getInfoParam('SERVERTIME'),"(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)")
      -- Если не удалось получить, или разрыв связи, ждет подключения и подгрузки с сервера актуальных данных
      if dt.day == nil or isConnected() == 0 then WaitUpdateDataAfterReconnect() end
   end
 
   -- Если во время ожидания скрипт был остановлен пользователем, возвращает таблицу datetime даты/времени компьютера, чтобы не вернуть пустую таблицу и не вызвать ошибку в алгоритме
   if not RUN then return os.date('*t', os.time()) end
 
   -- Приводит полученные значения к типу number
   for key,value in pairs(dt) do dt[key] = tonumber(value) end
 
   -- Возвращает итоговую таблицу
   return dt
end
-- Приводит время из строкового формата ЧЧ:ММ:СС к формату datetime
StrToTime = function(str_time)
   while RUN and GetServerDateTime().day == nil do sleep(100) end
   if not RUN then return os.date('*t', os.time()) end
   local dt = GetServerDateTime()
   local h,m,s = string.match( str_time, "(%d%d):(%d%d):(%d%d)")
   dt.hour = tonumber(h)
   dt.min = tonumber(m)
   dt.sec = tonumber(s)
   return dt
end


