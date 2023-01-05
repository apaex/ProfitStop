client_code = nil -- Код клиента (необязательный параметр в транзакции)
firmid = nil -- Идентификатор участника торгов
-- trdaccid = nil -- Номер счета Трейдера
class_code = "SPBFUT"

Transactions = {}


local function SendTransactionSync(transaction)
    local trans_id           = #Transactions + 1
    transaction["TRANS_ID"]  = tostring(trans_id)
    transaction["CLASSCODE"] = class_code

    Transactions[trans_id] = 0

    local result = sendTransaction(transaction)
    if result ~= "" then
        message(result, 3)
        Transactions[trans_id] = result
        return result
    end

    -- wait
    while IsRun and (Transactions[trans_id] == 0 or Transactions[trans_id].status <= 1) do
        sleep(100)
    end
    if Transactions[trans_id].status == 3 then
        return true
    else
        if Transactions[trans_id].result_msg ~= nil then
            message(Transactions[trans_id].result_msg, 3)
        end
        return Transactions[trans_id]
    end
end

function NewOrder(trdaccid, sec_code, qty, comment)
    local transaction = {
        ["ACTION"]   = "NEW_ORDER",
        ["SECCODE"]  = sec_code,
        ["TYPE"]     = "M",
        ["QUANTITY"] = tostring(math.abs(qty)),
        ["PRICE"]    = "0", -- tostring(getParamEx(CLASS_CODE_FUT, SEC_CODE_FUT_FOR_OPEN, "bid").param_value - 10*getParamEx(CLASS_CODE_FUT, SEC_CODE_FUT_FOR_OPEN, "SEC_PRICE_STEP").param_value), -- по цене, заниженной на 10 мин. шагов цены
        ["ACCOUNT"]  = trdaccid,
        ["COMMENT"]  = comment                
    }
    if qty > 0 then
        transaction["OPERATION"] = "B"
    else
        transaction["OPERATION"] = "S"
    end

    return SendTransactionSync(transaction)
end

function KillStopOrder(order_num, comment)
    local transaction = {
        ["ACTION"]         = "KILL_STOP_ORDER",
        ["STOP_ORDER_KEY"] = tostring(order_num),
        ["COMMENT"]        = comment
    }
    return SendTransactionSync(transaction)
end
