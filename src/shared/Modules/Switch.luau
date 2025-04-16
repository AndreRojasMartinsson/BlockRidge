--[=[
	Switch
	@date May 20, 2022
	@author RootEntry 2022
	@description Switch Case in Luau
]=]

local module = {}
module.__index = module

--[=[
	@prop input
	@prop callback
	@returns Switch
]=]
function module:case(input, callback)
	self.Cases[input] = callback
	return self
end

--[=[
	@prop callback
	@returns Switch
]=]
function module:default(callback)
	self.Cases["__default__"] = callback
	return self
end

--[=[
	@returns void
]=]
function module:exec()
	local executed = false
	for k, v in pairs(self.Cases) do
		if self.Expr == k then
			v()
			executed = true
			break
		end
	end

	if executed == false then
		if self.Cases["__default__"] then
			self.Cases["__default__"]()
		end
	end
end

--[=[
	@prop expression
	@returns Switch
]=]
return function(expression)
	local self = setmetatable({}, module)
	self.Expr = expression
	self.Cases = {}

	return self
end
