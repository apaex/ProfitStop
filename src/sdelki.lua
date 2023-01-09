function GetPositionParams(trdaccid, sec_code)
    local position = Last('futures_client_holding',
        function(t) return t.sec_code == sec_code and t.trdaccid == trdaccid end)
    if not position or position.totalnet == 0 then
        return 0
    end
    return position.totalnet
end

function GetTradersParams(qty, trdaccid, sec_code)

end

-- Получает цену текущей позиции
function GetPosPrice()

    local totalnet = self:GetTotalnet()
    -- Если позиция есть
    if totalnet ~= 0 then
        local abs_totalnet = math.abs(totalnet)
        local sum = 0
        local sum_lots = 0
        local trade = nil
        local broker_comission_sum = 0
        local exchange_comission_sum = 0

        -- Перебирает сделки
        local num = getNumberOf('trades')
        for i = num - 1, 0, -1 do
            trade = getItem('trades', i)
            if trade.sec_code == self.SEC_CODE then
                if (totalnet < 0 and bit.test(trade.flags, 2)) or (totalnet > 0 and not bit.test(trade.flags, 2)) then
                    sum = sum + trade.price * trade.qty
                    sum_lots = sum_lots + trade.qty
                    broker_comission_sum = broker_comission_sum + trade.broker_comission
                    exchange_comission_sum = exchange_comission_sum + trade.exchange_comission
                    -- Если найдены все сделки набора позиции
                    if sum_lots >= abs_totalnet then
                        -- корректировка
                        local delta = sum_lots - abs_totalnet -- излишек

                        sum = sum - trade.price * delta
                        sum_lots = sum_lots - delta
                        broker_comission_sum = broker_comission_sum - trade.broker_comission / trade.qty * delta
                        exchange_comission_sum = exchange_comission_sum - trade.exchange_comission / trade.qty * delta

                        return sum, broker_comission_sum, exchange_comission_sum
                    end
                end
            end
        end
    end
    -- Если не удалось получить значение, возвращает цену последней сделки по инструменту
    message('Не удалось получить стоимость открытия позиции из таблицы сделок'
        , 2)
end

--   СТОП

--    ЕСЛИ(
--       $H10>0;
----       ОКРВВЕРХ(
--            ( СУММА_ОТКРЫТИЯ + КОМИССИЯ / (СТОИМОСТЬ_ШАГА_ЦЕНЫ/ШАГ_ЦЕНЫ) ) / РАЗМЕР_ПОЗИЦИИ * ( 1 - РИСК / ( ( СУММА_ОТКРЫТИЯ * СТОИМОСТЬ_ШАГА_ЦЕНЫ/ШАГ_ЦЕНЫ + КОМИССИЯ) /$G10 ) );
--            ШАГ_ЦЕНЫ
--       );
--        ОКРВНИЗ(
--            ( СУММА_ОТКРЫТИЯ - КОМИССИЯ / (СТОИМОСТЬ_ШАГА_ЦЕНЫ/ШАГ_ЦЕНЫ) ) / РАЗМЕР_ПОЗИЦИИ * ( 1 + РИСК / ( ( СУММА_ОТКРЫТИЯ * СТОИМОСТЬ_ШАГА_ЦЕНЫ/ШАГ_ЦЕНЫ + КОМИССИЯ) /$G10 ) );
--            ШАГ_ЦЕНЫ
--       )
--   )

-- Инструмент	Кот. клиринга	Цена послед.	Точность	Шаг цены	Ст. шага цены	ГО продавца	Валюта шага цены	Время послед.	Код инструмента

function CalcStop(trdaccid, sec_code)
    -- из таблицы текущих торгов
    local price_step, step_price, scale, currency = GetParams(CLASS_CODE, sec_code,
        { 'SEC_PRICE_STEP', 'STEPPRICE', 'SEC_SCALE', 'CURSTEPPRICE' })
    message(sec_code ..
        ": Шаг цены " .. price_step ..
        ", Ст. шага цены " .. step_price ..
        ", Точность " .. scale ..
        ", Валюта шага цены " .. currency)
    -- из позиции
    local qty = GetPositionParams(trdaccid, sec_code)
    message(sec_code ..
        ": Количество в позиции " .. qty)
    -- из выборки по таблице сделок
    local price_sum, broker_comission_sum, exchange_comission_sum = GetTradersParams(qty)
    message(sec_code ..
        ": Сумма открытия " .. price_sum ..
        ", комиссия брокера " .. broker_comission_sum ..
        ", комиссия биржи " .. exchange_comission_sum)
    -- из счета?
    --local in_assets = 0







end
