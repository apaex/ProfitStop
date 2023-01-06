dofile(getScriptPath() .. "\\tools.lua")
dofile(getScriptPath() .. "\\transaction.lua")
dofile(getScriptPath() .. "\\config.lua")
setPrefix("PS")
IsRun = true

IsInit = false

function main()
	while IsRun do
		if isConnected() then
			if not IsInit then
				firmid, client_code = unpack(GetClientCode())
				message("Контроль риска установлен: " .. client_code .. " " .. firmid)

				DebugOut()
				IsInit = true
			end

			local per = GetClientRisk()
			local nPositions = GetPositionCount()

			if per > MAX_LOSS_PER and nPositions > 0 then
				message("Убыток " .. per .. "%, на сегодня всё", 2)

				DeleteAllStopOrders()
				CloseAllPositions()
			end
		end
		sleep(1000)
	end
end

function OnTransReply(t)
	if Transactions[t.trans_id] ~= nil then
		Transactions[t.trans_id] = t
	end
end

function OnInit()
end

function OnStop()
	IsRun = false
end

function GetClientCode()
	if FIRM_ID ~= nil and CLIENT_CODE ~= nil then
		return { FIRM_ID, CLIENT_CODE }
	end

	local search = SearchItems("money_limits", 0, getNumberOf("money_limits") - 1,
		function(t) return t.currentbal ~= 0 and t.limit_kind == 0 end)
	if search == nil or #search == 0 then
		return { nil, nil }
	end

	local row = getItem("money_limits", search[1])

	return { row.firmid, row.client_code }
end

function GetClientBallance()
	local t = getPortfolioInfo(firmid, client_code)
	if t ~= nil then
		return { t.in_assets, t.assets }
	end
	return { 0, 0 }
end

function GetClientRisk()
	local in_assets, assets = unpack(GetClientBallance())
	if in_assets == nil or in_assets == 0 then
		return 0
	end
	return (in_assets - assets) / in_assets * 100.
end

function DeleteStopOrder(t)
	if bit.test(t.flags, 0) and t.class_code == class_code then
		KillStopOrder(t.order_num)
	end
end

function DeleteAllStopOrders()
	ForEach("stop_orders", DeleteStopOrder)
end

function PositionFilter(t)
	return t.totalnet ~= 0
end

function ClosePosition(t)
	message("Закрываем позицию: " .. t.sec_code .. " : " .. t.totalnet)
	NewOrder(t.trdaccid, t.sec_code, -t.totalnet, "Закрытие позиции по убытку 3%")
end

function PrintPosition(t)
	message("Обнаружена позиция: " .. t.sec_code .. " : " .. t.totalnet)
end

function GetPositionCount()
	return CountOf("futures_client_holding", PositionFilter)
end

function CloseAllPositions()
	ForEach("futures_client_holding", ClosePosition, PositionFilter)
end

function PrintAllPositions()
	ForEach("futures_client_holding", PrintPosition, PositionFilter)
end

function DebugOut()
	local in_assets, assets = unpack(GetClientBallance())
	message("Входящие средства: " .. in_assets)
	message("Текущие средства: " .. assets)

	PrintAllPositions()
end
