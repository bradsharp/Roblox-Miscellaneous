local check

local function lookup(tab)
	local val = tab[check]
	if type(val) == "function" then return val() end
	return val
end

return function (var)
	check = var
	return lookup
end
