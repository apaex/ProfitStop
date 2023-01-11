function makeKey(t, key)
	if t == nil then
		return nil
	end

	res = {}
	for i, v in ipairs(t) do
		if v[key] ~= nil then
			res[v[key]] = v
		end
	end
	return res
end

-- получаем все ключи таблицы
function keys(t)
	res = {}
	for key, v in pairs(t) do
		res[#res + 1] = key
	end
	return res
end

-- получаем все значения таблицы
function values(t)
	res = {}
	for key, v in pairs(t) do
		res[#res + 1] = v
	end
	return res
end

function makePairs(keys, values)
	local t = {}
	for i = 1, #keys do
		t[keys[i]] = values[i]
	end
	return t
end

function join(t, c)
	local s = ""
	for key, v in pairs(t) do
		s = s .. v .. c
	end
	return #s > 0 and string.sub(s, 1, #s - 1) or "";
end

function split(s, c)
	local result = {}

	local index = 1
	for s in string.gmatch(s, "[^" .. c .. "]*") do
		result[index] = s

		index = index + 1
	end

	return result
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
