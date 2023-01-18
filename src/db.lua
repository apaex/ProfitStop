db = {
    trades =
    {
        name = 'trades',
        fields = {
            { name = 'trade_num', type = "INTEGER" },
            { name = 'datetime', type = "DATATIME" },
            { name = 'account', type = "TEXT" },
            { name = 'class_code', type = "TEXT" },
            { name = 'sec_code', type = "TEXT" },
            { name = 'price', type = "REAL" },
            { name = 'qty', type = "INTEGER" },
            { name = 'value', type = "REAL" },
            { name = 'exchange_comission', type = "REAL" },
            { name = 'broker_comission', type = "REAL" },
            { name = 'order_num', type = "INTEGER" }
        },
        primary = 'trade_num',
        index = 'order_num'
    }
}

setmetatable(db.trades, { __index = DBTable })


function db.trades:GetGroupTraders()
    local fields = {
        'order_num', 'datetime', 'account', 'class_code', 'sec_code', 'qty', 'value', 'exchange_comission', 'broker_comission'
    } -- порядок в запросе должен точно соответствовать

    local sql = [[SELECT order_num, MIN(datetime) AS datetime, account, class_code, sec_code, SUM(qty) AS qty,SUM(value) AS value,SUM(exchange_comission) AS exchange_comission , SUM(broker_comission) AS broker_comission FROM trades
    GROUP BY order_num
    ORDER BY datetime ASC]]

    local cursor, errorString = self.conn:execute(sql)
    if not cursor then
        message(errorString, 2)
        return nil
    end

    local res = {}

    local row = cursor:fetch({})
    while row do
        res[#res + 1] = makePairs(fields, row)
        row = cursor:fetch({})
    end

    cursor:close()
    return res, fields
end
