Engine = {}
Engine.trans_id = os.time()

function Engine:new(trdaccid, sec_code)
    newObj = {}

    newObj.ACCOUNT     = trdaccid
    newObj.SEC_CODE    = sec_code -- Код бумаги
    newObj.STOP_SIZE   = STOP_SIZE -- Размер стопа в минимальных шагах цены (если 0, ставится только профит)
    newObj.PROFIT_SIZE = PROFIT_SIZE -- Размер профита в минимальных шагах цены (если 0, ставится только стоп)

    -- Получает минимальный шаг цены инструмента
    newObj.PriceStep = tonumber(getParamEx(CLASS_CODE, sec_code, "SEC_PRICE_STEP").param_value)

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
                    message("вот здесь позиция изменилась при активной стоп-заявке бота "
                        .. totalnet)
                    -- Запоминает, что нужно перевыставить стоп-заявку в те же цены
                    if MOVE_STOP_BY_POS == 0 and
                        ((self.StopPos > 0 and totalnet < 0) or (self.StopPos < 0 and totalnet > 0)) then
                        NeedSetToOldPricesLevels = true
                    end
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
                -- Получает максимально возможную цену заявки
                self.PriceMax = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'PRICEMAX').param_value)
                -- Получает минимально возможную цену заявки
                self.PriceMin = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'PRICEMIN').param_value)

                -- запоминает изменение позиции стоп-заявкой
                self.StopPos = -totalnet

                -- Получает цену текущей позиции
                local pos_price = self:GetPosPrice()
                -- Получает количество лотов без знака в заявке
                local qty = math.floor(math.abs(totalnet))
                -- Определяет направление стоп-заявки
                local operation = totalnet > 0 and 'S' or 'B'

                local profit_size = self.PROFIT_SIZE -- Размер профита в шагах цены
                local stop_size = self.STOP_SIZE -- Размер стопа в шагах цены

                -- Нужно выставить в те же цены
                if NeedSetToOldPricesLevels then
                    -- Получает цены из снятой стоп-заявки
                    local profit_price, stop_price = self:GetStopOrderPrices(self.StopOrderNum)

                    if totalnet > 0 then
                        profit_size = profit_size == 0 and 0 or
                            math.floor(math_round((profit_price - pos_price) / self.PriceStep))
                        stop_size = stop_size == 0 and 0 or
                            math.floor(math_round((pos_price - stop_price) / self.PriceStep))
                    else
                        profit_size = profit_size == 0 and 0 or
                            math.floor(math_round((pos_price - profit_price) / self.PriceStep))
                        stop_size = stop_size == 0 and 0 or
                            math.floor(math_round((stop_price - pos_price) / self.PriceStep))
                    end
                end

                -- Выставляет "Тейк профит и Стоп лимит" заявку
                self:SetTP_SL(
                    operation, -- Операция ('B', или 'S')
                    pos_price, -- Цена позиции, на которую выставляется стоп-заявка
                    qty, -- Количество лотов
                    profit_size, -- Размер профита в шагах цены
                    stop_size-- Размер стопа в шагах цены
                )

                -- Если робот аварийно завршил работу, выходит из функции
                if not IsRun then return end

                -- Запоминает номер стоп-заявки
                self.StopOrderNum = self:GetStopOrderNum(Engine.trans_id)
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

    local totalnet = self:GetTotalnet()
    -- Если позиция есть
    if totalnet ~= 0 then
        local abs_totalnet = math.abs(totalnet)
        local sum = 0
        local sum_lots = 0
        local trade = nil
        -- Перебирает сделки
        local num = getNumberOf('trades')
        for i = num - 1, 0, -1 do
            trade = getItem('trades', i)
            if trade.sec_code == self.SEC_CODE then
                if (totalnet < 0 and bit.test(trade.flags, 2)) or (totalnet > 0 and not bit.test(trade.flags, 2)) or
                    totalnet == 0 then
                    sum = sum + trade.price * trade.qty
                    sum_lots = sum_lots + trade.qty
                    -- Если найдены все сделки набора позиции
                    if sum_lots >= abs_totalnet then
                        -- Возвращает среднюю цену
                        -- message('ddd ' .. totalnet)
                        return sum / sum_lots
                    end
                end
            end
        end
        -- Не удалось найти все сделки набора позиции
        -- Если найдены хоть какие-то сделки набора
        if sum_lots > 0 then
            -- Возвращает среднюю цену найденных
            return sum / sum_lots
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
                        if futures_client_holding.sec_code == self.SEC_CODE and
                            futures_client_holding.trdaccid == self.ACCOUNT then
                            return futures_client_holding.avrposnprice
                        end
                    end
                else
                    futures_client_holding = getItem('futures_client_holding', 0)
                    if futures_client_holding.sec_code == self.SEC_CODE and
                        futures_client_holding.trdaccid == self.ACCOUNT then
                        return futures_client_holding.avrposnprice
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

    local num = getNumberOf('futures_client_holding')
    if num > 0 then
        -- Находит размер лота
        local lot = tonumber(getParamEx(CLASS_CODE, self.SEC_CODE, 'LOTSIZE').param_value)

        for i = 0, num - 1 do
            local futures_client_holding = getItem('futures_client_holding', i)
            if futures_client_holding.sec_code == self.SEC_CODE and
                futures_client_holding.trdaccid == self.ACCOUNT then
                if BALANCE_TYPE == 1 then
                    return futures_client_holding.totalnet
                else
                    return futures_client_holding.totalnet / lot
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
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
                    self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
                    self.STOP_SIZE = 0
                    -- тейк-профит и стоп-лимит
                elseif stop_order.stop_order_type == 9 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price2) / self.PriceStep
                    -- стоп-лимит
                elseif stop_order.stop_order_type == 1 then
                    self.PROFIT_SIZE = 0
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                end
                -- ШОРТ
            else
                -- Тейк-профит
                if stop_order.stop_order_type == 6 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                    self.STOP_SIZE = 0
                    -- тейк-профит и стоп-лимит
                elseif stop_order.stop_order_type == 9 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (stop_order.condition_price2 - self:GetPosPrice()) / self.PriceStep
                    -- стоп-лимит
                elseif stop_order.stop_order_type == 1 then
                    self.PROFIT_SIZE = 0
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
                end
            end
            break
        end
    end
end

-- Получает цены из стоп-заявки (profit_price, stop_price)
function Engine:GetStopOrderPrices(order_num)
    -- Перебирает таблицу стоп-заявок от последней к первой
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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

-- Выставляет "Тейк профит и Стоп лимит" заявку
function Engine:SetTP_SL(
    operation, -- Операция ('B', или 'S')
    pos_price, -- Цена позиции, на которую выставляется стоп-заявка
    qty, -- Количество лотов
    profit_size, -- Размер профита в шагах цены
    stop_size -- Размер стопа в шагах цены
)
    message("СТОП: " ..
        self.SEC_CODE .. " " ..
        operation .. ":" .. qty .. ", цена позиции " ..
        pos_price .. ", профит " .. profit_size .. ", стоп " .. stop_size)

    -- Получает ID для следующей транзакции
    Engine.trans_id = Engine.trans_id + 1

    -- Заполняет структуру для отправки транзакции на Стоп-лосс и Тэйк-профит
    local T        = {}
    T['TRANS_ID']  = tostring(Engine.trans_id)
    T['CLASSCODE'] = CLASS_CODE
    T['SECCODE']   = self.SEC_CODE
    T['ACCOUNT']   = self.ACCOUNT
    T['ACTION']    = 'NEW_STOP_ORDER' -- Тип заявки
    T['OPERATION'] = operation -- Операция ('B' - покупка(BUY), 'S' - продажа(SELL))
    T['QUANTITY']  = tostring(qty) -- Количество в лотах

    if profit_size > 0 then
        -- Вычисляет цену профита
        local stopprice   = self:OffsetPrice(operation, pos_price, -profit_size * self.PriceStep)
        T['STOPPRICE']    = self:GetCorrectPrice(stopprice) -- Цена Тэйк-Профита
        T['OFFSET']       = '0' -- отступ
        T['OFFSET_UNITS'] = 'PRICE_UNITS' -- в шагах цены

        local spread_p    = self:OffsetPrice(operation, stopprice, ORDER_PRICE_OFFSET * self.PriceStep,
            IGNORE_TP_LIMITS)
        local spread      = math.abs(spread_p - stopprice) -- если не нужна проверка лимитов, то можно вообще = ORDER_PRICE_OFFSET * self.PriceStep
        T['SPREAD']       = self:GetCorrectPrice(spread) -- Защитный спред
        T['SPREAD_UNITS'] = 'PRICE_UNITS' -- в шагах цены
    end

    if stop_size > 0 then
        -- Вычисляет цену стопа
        local stopprice2 = self:OffsetPrice(operation, pos_price, stop_size * self.PriceStep)
        T['STOPPRICE2'] = self:GetCorrectPrice(stopprice2) -- Цена Стоп-Лосса

        -- Вычисляет цену, по которой выставится заявка при срабатывании стопа
        local price = self:OffsetPrice(operation, stopprice2, ORDER_PRICE_OFFSET * self.PriceStep)
        T['PRICE']  = self:GetCorrectPrice(price) -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
    end

    if profit_size > 0 and stop_size > 0 then
        T['STOP_ORDER_KIND'] = 'TAKE_PROFIT_AND_STOP_LIMIT_ORDER' -- Тип стоп-заявки
        T['MARKET_STOP_LIMIT'] = 'YES' -- 'YES', или 'NO'
        T['MARKET_TAKE_PROFIT'] = 'YES' -- 'YES', или 'NO'
    elseif stop_size == 0 then
        T['STOP_ORDER_KIND'] = 'TAKE_PROFIT_STOP_ORDER'
    elseif profit_size == 0 then
        T['STOP_ORDER_KIND'] = 'SIMPLE_STOP_ORDER'
        T['STOPPRICE']       = T['STOPPRICE2']
    end

    T['EXPIRY_DATE']       = 'GTC' -- 'TODAY', 'GTC', или время
    T['IS_ACTIVE_IN_TIME'] = 'NO' -- Признак действия заявки типа «Тэйк-профит и стоп-лимит» в течение определенного интервала времени. Значения «YES» или «NO»
    T['CLIENT_CODE']       = 'AS' -- Комментарий

    -- Отправляет транзакцию
    local Res = sendTransaction(T)
    if Res ~= '' then
        message(self.SEC_CODE .. ' Ошибка выставления стоп-заявки: ' .. Res)
        OnStop()
    end
end

-- Возвращает номер активной стоп-заявки с соответствующим комментарием, либо nil
function Engine:GetActiveStopOrderNumByComment(comment)
    -- Перебирает таблицу стоп-заявок от последней к первой
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
                    self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
                    -- тейк-профит и стоп-лимит
                elseif stop_order.stop_order_type == 9 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price2) / self.PriceStep
                    -- стоп-лимит
                elseif stop_order.stop_order_type == 1 then
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                end
                -- ШОРТ
            else
                -- Тейк-профит
                if stop_order.stop_order_type == 6 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                    -- тейк-профит и стоп-лимит
                elseif stop_order.stop_order_type == 9 then
                    -- Вычисляет размер профита
                    self.PROFIT_SIZE = (self:GetPosPrice() - stop_order.condition_price) / self.PriceStep
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (stop_order.condition_price2 - self:GetPosPrice()) / self.PriceStep
                    -- стоп-лимит
                elseif stop_order.stop_order_type == 1 then
                    -- Вычисляет размер стопа
                    self.STOP_SIZE = (stop_order.condition_price - self:GetPosPrice()) / self.PriceStep
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
    while IsRun do
        -- Перебирает таблицу стоп-заявок от последней к первой
        for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
    stop_order_num -- Номер снимаемой стоп-заявки
)
    -- Находит стоп-заявку (30 сек. макс.)
    local index = 0
    local start_sec = os.time()
    local find_so = false
    while IsRun and not find_so and os.time() - start_sec < 30 do
        for i = getNumberOf('stop_orders') - 1, 0, -1 do
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
        message(self.SEC_CODE .. ' Ошибка: не найдена стоп-заявка!')
        return false
    end

    -- Получает ID для следующей транзакции
    Engine.trans_id     = Engine.trans_id + 1
    -- Заполняет структуру для отправки транзакции на снятие стоп-заявки
    local T             = {}
    T['TRANS_ID']       = tostring(Engine.trans_id)
    T['CLASSCODE']      = CLASS_CODE
    T['SECCODE']        = self.SEC_CODE
    T['ACTION']         = 'KILL_STOP_ORDER' -- Тип заявки
    T['STOP_ORDER_KEY'] = tostring(stop_order_num) -- Номер стоп-заявки, снимаемой из торговой системы

    -- Отправляет транзакцию
    local Res = sendTransaction(T)
    -- Если при отправке транзакции возникла ошибка
    if Res ~= '' then
        -- Выводит ошибку
        message(self.SEC_CODE .. ' Ошибка снятия стоп-заявки: ' .. Res)
        return false
    end

    -- Ожидает когда стоп-заявка перестанет быть активна (30 сек. макс.)
    start_sec = os.time()
    local active = true
    while IsRun and os.time() - start_sec < 30 do
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
        message(self.SEC_CODE .. ' Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
        return false
    end

    return true
end

-- Снимает все стоп-заявки по инструменту
function Engine:KillAll_SO()
    for i = getNumberOf('stop_orders') - 1, 0, -1 do
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

    -- Если после запятой должны быть цифры
    if scale > 0 then
        price = tostring(price)
        -- Ищет в числе позицию запятой, или точки
        local dot_pos = price:find('.')
        local comma_pos = price:find(',')
        -- Если передано целое число
        if dot_pos == nil and comma_pos == nil then
            -- Добавляет к числу ',' и необходимое количество нулей и возвращает результат
            price = price .. ','
            for i = 1, scale do price = price .. '0' end
            return price
        else -- передано вещественное число
            -- Если нужно, заменяет запятую на точку
            if comma_pos ~= nil then price:gsub(',', '.') end
            -- Округляет число до необходимого количества знаков после запятой
            price = math_round(tonumber(price), scale)
            -- Корректирует на соответствие шагу цены
            price = math_round(price / self.PriceStep) * self.PriceStep
            price = string.gsub(tostring(price), '[%.]+', ',')
            return price
        end
    else -- После запятой не должно быть цифр
        -- Корректирует на соответствие шагу цены
        price = math_round(price / self.PriceStep) * self.PriceStep
        return tostring(math.floor(price))
    end
end

function Engine:OffsetPrice(operation, price, offs, ignore_limits)
    if operation == 'B' then
        price = price + offs
        if not ignore_limits and self.PriceMax ~= nil and self.PriceMax ~= 0 and price > self.PriceMax then
            price = self.PriceMax
        end
    elseif operation == 'S' then
        price = price - offs
        if not ignore_limits and self.PriceMin ~= nil and self.PriceMin ~= 0 and price < self.PriceMin then
            price = self.PriceMin
        end
    end
    return price
end
