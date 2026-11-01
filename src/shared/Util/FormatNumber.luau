--!strict
local FormatNumber = {}
local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi"}
function FormatNumber.Format(value: number): string
	if value ~= value or math.abs(value) == math.huge then return "0" end
	local sign = if value < 0 then "-" else ""
	local amount = math.abs(value)
	local index = 1
	while amount >= 1000 and index < #suffixes do
		amount /= 1000
		index += 1
	end
	if index == 1 then return sign .. tostring(math.floor(amount)) end
	amount = math.floor(amount * 10 + 0.5) / 10
	if amount >= 1000 and index < #suffixes then amount /= 1000; index += 1 end
	return sign .. string.gsub(string.format("%.1f", amount), "%.0$", "") .. suffixes[index]
end
return FormatNumber
