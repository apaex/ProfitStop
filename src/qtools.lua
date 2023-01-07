function GetServerTime()
    local dt = {};
    dt.day, dt.month, dt.year, dt.hour, dt.min, dt.sec = string.match(getInfoParam('TRADEDATE') ..
        ' ' .. getInfoParam('SERVERTIME'), "(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)")
    for key, value in pairs(dt) do dt[key] = tonumber(value) end
    return dt
end

function GetParam(class, sec, param)
    local v = getParamEx(class, sec, param)
    if tonumber(v.result) == 0 then
        message("Ошибка получения параметра " .. param .. " для " ..
            class .. ":" .. sec, 2)
        return nil
    end

    if (tonumber(v.param_type) == 3) or (tonumber(v.param_type) == 4) then
        return v.param_image
    else
        return tonumber(v.param_value)
    end
end

function GetParams(class, sec, params)
    local result = {}
    for key, value in pairs(params) do
        result[key] = GetParam(class, sec, value)
    end
    return unpack(result)
end

-- экспорт таблицы QUIK

function SaveToCSV(name)
    local n = getNumberOf(name)
    if n == 0 then
        return
    end
    local row = getItem(name, 0)

    local file = io.open(getScriptPath() .. "\\" .. name .. ".csv", "w")

    for key, v in pairs(row) do
        file:write(key .. ";")
    end
    file:write("\n")

    for i = 0, n - 1 do
        row = getItem(name, i)

        for key, v in pairs(row) do
            file:write(v .. ";")
        end
        file:write("\n")
    end

    file:close()
end

-- функции работы с таблицами QUIK

function ForEach(name, func, filter)
    if filter ~= nil then -- если фильтр задан, то строим выборку, потом перебираем, а если не задан - то перебираем всё
        local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
        if search == nil then
            return
        end

        for i, v in ipairs(search) do
            if func(getItem(name, v)) then break end
        end
    else
        local n = getNumberOf(name)
        for i = 0, n - 1 do
            if func(getItem(name, i)) then break end
        end
    end
end

function First(name, filter)
    local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
    if search == nil or #search == 0 then
        return
    end

    return getItem(name, search[1])
end

function Last(name, filter)
    local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
    if search == nil or #search == 0 then
        return
    end

    return getItem(name, search[#search])
end

function CountOf(name, filter)
    local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
    if search == nil then
        return 0
    end
    return #search
end
