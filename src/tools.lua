function setPrefix(prefix)
	PrintDbgStr_ = PrintDbgStr
	PrintDbgStr = function(v)
		if v == nil then
			message("PrintDbgStr(nil)", 2)
			PrintDbgStr_(prefix .. " " .. "PrintDbgStr(nil)")
		else
			PrintDbgStr_(prefix .. " " .. v)
		end
	end
	message_ = message
	message = function(v, l)
		message_(v, l)
		PrintDbgStr(v)
	end
end

function DebugWrite(v)
	if type(v) == "table" then
		for key, value in pairs(v) do
			PrintDbgStr(key .. " = (" .. type(value) .. ") " .. value)
		end
	else
		PrintDbgStr(v)
	end
end

function printTable(name)
	n = getNumberOf(name)
	order = {}

	tablePrintDbgStr("TABLE " .. name .. "[" .. tostring(n) .. "]")

	for i = 0, n - 1 do
		order = getItem(name, i)
		tablePrintDbgStr(tostring(i) .. ":")
		tablePrintDbgStr(order)
	end
end

function nz(v, nv)
	return v ~= nil and v or nv or 'nil'
end

-- Округляет число до указанной точности
function math_round(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

UpdateDataSecQty = 10 -- Количество секунд ожидания подгрузки данных с сервера после возобновления подключения

-- Ждет подключения к серверу, после чего ждет еще UpdateDataSecQty секунд подгрузки пропущенных данных с сервера
function WaitUpdateDataAfterReconnect()
	while IsRun and isConnected() == 0 do sleep(100) end
	if IsRun then sleep(UpdateDataSecQty * 1000) end
	-- Повторяет операцию если соединение снова оказалось разорвано
	if IsRun and isConnected() == 0 then WaitUpdateDataAfterReconnect() end
end

-- Возвращает текущую дату/время сервера в виде таблицы datetime
function GetServerDateTime()
	local dt = {}

	-- Пытается получить дату/время сервера
	while IsRun and dt.day == nil do
		dt.day, dt.month, dt.year, dt.hour, dt.min, dt.sec = string.match(getInfoParam('TRADEDATE') ..
			' ' .. getInfoParam('SERVERTIME'), "(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)")
		-- Если не удалось получить, или разрыв связи, ждет подключения и подгрузки с сервера актуальных данных
		if dt.day == nil or isConnected() == 0 then WaitUpdateDataAfterReconnect() end
	end

	-- Если во время ожидания скрипт был остановлен пользователем, возвращает таблицу datetime даты/времени компьютера, чтобы не вернуть пустую таблицу и не вызвать ошибку в алгоритме
	if not IsRun then return os.date('*t', os.time()) end

	-- Приводит полученные значения к типу number
	for key, value in pairs(dt) do dt[key] = tonumber(value) end

	-- Возвращает итоговую таблицу
	return dt
end

-- Приводит время из строкового формата ЧЧ:ММ:СС к формату datetime
function StrToTime(str_time)
	while IsRun and GetServerDateTime().day == nil do sleep(100) end
	if not IsRun then return os.date('*t', os.time()) end
	local dt = GetServerDateTime()
	local h, m, s = string.match(str_time, "(%d%d):(%d%d):(%d%d)")
	dt.hour = tonumber(h)
	dt.min = tonumber(m)
	dt.sec = tonumber(s)
	return dt
end
