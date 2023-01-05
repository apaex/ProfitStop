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

function saveAllToCSV()
	local params = {
		"firms",
		"classes",
		"securities",
		"trade_accounts",
		-- "client_codes",
		"all_trades",
		"account_positions",
		-- "orders",
		"futures_client_holding",
		"futures_client_limits",
		"money_limits",
		"depo_limits",
		-- "trades",
		"stop_orders",
		"neg_deals",
		"neg_trades",
		"neg_deal_reports",
		"firm_holding",
		"account_balance",
		"ccp_holdings",
		"rm_holdings"
	}

	for i, v in ipairs(params) do
		saveToCSV(v)
	end
end

function saveToCSV(name)
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

-- если фильтр задан, то строим выборку, потом перебираем, а если не задан - то перебираем всё
function ForEach(name, func, filter)
	if filter ~= nil then
		local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
		if search == nil then
			return
		end
		for i, v in ipairs(search) do
			func(getItem(name, v))
		end
	else
		local n = getNumberOf(name)
		for i = 0, n - 1 do
			func(getItem(name, i))
		end
	end
end

function CountOf(name, filter)
	local search = SearchItems(name, 0, getNumberOf(name) - 1, filter)
	if search == nil then
		return 0
	end
	return #search
end
