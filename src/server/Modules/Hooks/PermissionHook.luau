local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Environment = Config("Environment")

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == "Admin" then
			if table.find(Environment.Admins, context.Executor.UserId) then
				return nil
			end

			if table.find(Environment.Root, context.Executor.UserId) then
				return nil
			end

			return "You do not have the necessary permissions to run this command."
		elseif context.Group == "Mod" then
			if table.find(Environment.Admins, context.Executor.UserId) then
				return nil
			end

			if table.find(Environment.Root, context.Executor.UserId) then
				return nil
			end

			if table.find(Environment.Moderators, context.Executor.UserId) then
				return nil
			end

			return "You do not have the necessary permissions to run this command."
		elseif context.Group == "Root" then
			if table.find(Environment.Root, context.Executor.UserId) then
				return nil
			end

			return "You do not have the necessary permissions to run this command."
		end
	end)
end
