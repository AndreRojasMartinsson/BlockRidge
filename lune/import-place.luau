local downloadPlaceAsset = require("lib/downloadPlaceAsset")
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

function importPlace(placeId)
	local content = downloadPlaceAsset(placeId)
	local game = roblox.deserializePlace(content)

	if not fs.isDir("./map") then
		fs.writeDir("./map")
	end

	if not fs.isDir("./assets") then
		fs.writeDir("./assets")
	end

	fs.writeFile("./map/SetupAnimations.rbxm", roblox.serializeModel({ game.ServerScriptService.SetupAnimations }))

	fs.writeFile("./map/ServerStorage.rbxm", roblox.serializeModel({ game.ServerStorage }))

	fs.writeFile("./map/LocalScript.rbxm", roblox.serializeModel({ game.StarterGui.LocalScript }))
	fs.writeFile("./map/Streaming.rbxm", roblox.serializeModel({ game.StarterGui.Streaming }))
	fs.writeFile("./map/Interact.rbxm", roblox.serializeModel({ game.StarterGui.Interact }))
	fs.writeFile("./map/Interface.rbxm", roblox.serializeModel({ game.StarterGui.Interface }))
	fs.writeFile("./map/Notifications.rbxm", roblox.serializeModel({ game.StarterGui.Notifications }))

	fs.writeFile("./map/Workspace.rbxm", roblox.serializeModel({ game.Workspace }))
	fs.writeFile("./map/Lighting.rbxm", roblox.serializeModel({ game.Lighting }))
	fs.writeFile("./map/Accessories.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Accessories }))
	fs.writeFile("./map/Assets.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Assets }))
	fs.writeFile("./map/Buffer.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Buffer }))
	fs.writeFile("./map/StaticStreaming.rbxm", roblox.serializeModel({ game.ReplicatedStorage.StaticStreaming }))

	fs.writeFile("./map/Consent.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Consent }))
	fs.writeFile("./map/ConsentOverride.rbxm", roblox.serializeModel({ game.ReplicatedStorage.ConsentOverride }))
	fs.writeFile("./map/Clothing.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Clothing }))
	fs.writeFile("./map/gizmo.rbxm", roblox.serializeModel({ game.ReplicatedStorage.gizmo }))
	fs.writeFile("./map/PatternChange.rbxm", roblox.serializeModel({ game.ReplicatedStorage.PatternChange }))

	fs.writeFile("./map/Armoury.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Armoury }))
	fs.writeFile("./map/GiveItem.rbxm", roblox.serializeModel({ game.ReplicatedStorage.GiveItem }))
	fs.writeFile("./map/IntFinished.rbxm", roblox.serializeModel({ game.ReplicatedStorage.IntFinished }))
	fs.writeFile("./map/Locker.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Locker }))
	fs.writeFile("./map/Search.rbxm", roblox.serializeModel({ game.ReplicatedStorage.Search }))
	fs.writeFile("./map/StreamingFinished.rbxm", roblox.serializeModel({ game.ReplicatedStorage.StreamingFinished }))
	fs.writeFile("./map/VehicleClient.rbxm", roblox.serializeModel({ game.ReplicatedStorage.VehicleClient }))
end

importPlace(10329313794)
