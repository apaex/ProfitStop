function GetPositionParams(trdaccid, sec_code)
    local position = Last('futures_client_holding',
        function(t) return t.sec_code == sec_code and t.trdaccid == trdaccid end)
    if not position or position.totalnet == 0 then
        return
    end
    return position.totalnet
end

function GetTradersParams(qty, trdaccid, sec_code)

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
        ": Шаг цены " ..
        price_step .. ", Ст. шага цены " ..
        step_price .. ", Точность " .. scale .. ", Валюта шага цены " .. currency)
    -- из позиции
    --local qty = GetPositionParams(trdaccid, sec_code)
    -- из выборки по таблице сделок
    --local price_sum, broker_comission_sum, exchange_comission_sum = GetTradersParam(qty)
    -- из счета?
    --local in_assets = 0







end
