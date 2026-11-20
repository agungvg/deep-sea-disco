--!strict
-- Deep Sea Disco: reviewer tour hooks. TOUR.json names these so a reviewer
-- in Studio can bring the game to each screenshot state with one call.
-- Each function is a thin, safe wrapper around the server's own systems.

local Tour = {}

-- Spawn one critter of the named id in the Open Water (arg: critter id).
function Tour.spawnCritter(arg: string): string
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Characters = require(ReplicatedStorage:WaitForChild("Shared").Characters)
	local def = Characters.ById[arg]
	if def == nil then
		return "unknown critter: " .. arg
	end
	local folder = workspace:FindFirstChild("WildCritters")
	if folder == nil then
		return "game not booted yet"
	end
	local CharacterFactory = require(script.Parent.CharacterFactory)
	local model = CharacterFactory.build(def, Vector3.new(0, 0, -30), 0)
	model.Parent = folder
	return "spawned " .. def.name
end

-- Start Disco Fever now (arg ignored).
function Tour.startFever(_arg: string): string
	local Events = require(script.Parent.Events)
	Events.startFever(function(title: string, _subtitle: string)
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local juice = remotes and remotes:FindFirstChild("Juice") :: RemoteEvent?
		if juice then
			juice:FireAllClients("event", title, "Every base pays x2 Bubbles for 45 seconds!")
		end
	end)
	return "Disco Fever started"
end

return Tour
