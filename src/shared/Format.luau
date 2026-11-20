--!strict
-- Deep Sea Disco: shared formatting helpers. Pure functions, no state,
-- so the server and the client always spell the same number the same way.

local Format = {}

-- 1234567 -> "1,234,567". 1234 -> "1,234".
function Format.withCommas(value: number): string
	local whole = math.floor(value)
	local text = tostring(whole)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return text .. out
end

-- Big Bubbles counts shorten: 1,300,000 -> "1.3M", 773,800 -> "773.8K".
function Format.short(value: number): string
	if value >= 1_000_000 then
		return string.format("%.1fM", value / 1_000_000)
	elseif value >= 10_000 then
		return string.format("%.1fK", value / 1_000)
	elseif value >= 1_000 then
		return string.format("%.2fK", value / 1_000)
	else
		return Format.withCommas(value)
	end
end

-- A rate line: 312 -> "+312/s".
function Format.rate(value: number): string
	return "+" .. Format.short(value) .. "/s"
end

-- 45 -> "0:45", 135 -> "2:15".
function Format.clock(seconds: number): string
	local left = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end

return Format
