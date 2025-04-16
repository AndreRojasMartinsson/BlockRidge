local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {},
})

function DataService:_YieldRequest(RequestType)
	return Promise.new(function(resolve)
		local CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)

		while CurrentBudget < 1 do
			CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
			task.wait(5)
		end

		resolve()
	end)
end

function DataService:_SafeCall(request, store, key, requestType, noWait, callback)
	return Promise.new(function(resolve, reject)
		local success, ret
		local count = 0

		while not success do
			if count >= 1 then
				if noWait then
					warn("[DataService] [::SafeCall] [Broke Loop] Error Occured: " .. ret)
					break
				end

				if count > 6 then
					warn("[DataService] [::SafeCall] [Broke Loop] Error Occured: " .. ret)
					break
				end

				warn("[DataService] [::SafeCall] Error Occured: " .. ret)
				task.wait(count ^ 2)
			end

			self:_YieldRequest(requestType):await()
			if callback and requestType == Enum.DataStoreRequestType.UpdateAsync then
				success, ret = pcall(request, store, key, callback)
			elseif requestType == Enum.DataStoreRequestType.GetAsync then
				success, ret = pcall(request, store, key)
			end
			count += 1
		end

		if success then
			resolve(ret)
		else
			reject(ret)
		end
	end)
end

function DataService:Set(Name, Scope, Key, Callback)
	return Promise.new(function(resolve, reject)
		local Store = DataStoreService:GetDataStore(Name, Scope)
		local success, ret = self
			:_SafeCall(Store.UpdateAsync, Store, Key, Enum.DataStoreRequestType.UpdateAsync, false, Callback)
			:await()

		if success then
			resolve(ret)
		else
			reject(ret)
		end
	end)
end

function DataService:Get(Name, Scope, Key)
	return Promise.new(function(resolve, reject)
		local Store = DataStoreService:GetDataStore(Name, Scope)
		local success, ret =
			self:_SafeCall(Store.GetAsync, Store, Key, Enum.DataStoreRequestType.GetAsync, false):await()

		if success then
			resolve(ret)
		else
			reject(ret)
		end
	end)
end

return DataService
