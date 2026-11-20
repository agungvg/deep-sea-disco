--!strict
-- Deep Sea Disco: the two map-wide live events that are not the Net Nabber.
-- Disco Fever: every base pays double Bubbles for 45 seconds.
-- Shark Sweep: a shark crosses the dance floor and anyone carrying a
-- critter who touches it drops the critter and gets knocked back.
-- Both announce with a full-width banner and a sting on every client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Events = {}

local feverUntil = 0

function Events.isFever(): boolean
	return os.clock() < feverUntil
end

function Events.feverLeft(): number
	return math.max(0, feverUntil - os.clock())
end

function Events.startFever(announce: (string, string) -> ())
	feverUntil = os.clock() + Config.Events.DiscoFever.duration
	announce("DISCO FEVER!", "Every base pays x2 Bubbles for 45 seconds!")
end

-- Build a shark, swim it across the dance floor, then clean it up.
-- onHit is called with each player the shark touches (server decides).
function Events.runSharkSweep(announce: (string, string) -> (), onHit: (Player) -> ())
	announce("SHARK SWEEP!", "STAY OUT OF THE DEEP — a shark is crossing the floor!")
	local shark = Instance.new("Model")
	shark.Name = "SharkSweep"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 2, 9)
	body.Color = Color3.fromRGB(120, 140, 170)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(-80, 2.5, 8)
	body.Parent = shark
	shark.PrimaryPart = body
	local fin = Instance.new("Part")
	fin.Name = "Fin"
	fin.Shape = Enum.PartType.Wedge
	fin.Size = Vector3.new(0.4, 2.5, 2)
	fin.Color = Color3.fromRGB(90, 110, 140)
	fin.Material = Enum.Material.SmoothPlastic
	fin.Anchored = true
	fin.CanCollide = false
	fin.CFrame = CFrame.new(-80, 4.2, 8)
	fin.Parent = shark
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Shape = Enum.PartType.Wedge
	tail.Size = Vector3.new(1.5, 2.5, 0.5)
	tail.Color = Color3.fromRGB(90, 110, 140)
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = true
	tail.CanCollide = false
	tail.CFrame = CFrame.new(-80, 2.5, 13)
	tail.Parent = shark
	shark.Parent = workspace

	local Players = game:GetService("Players")
	local alreadyHit = {}
	local startClock = os.clock()
	local cross = Config.Events.SharkSweep.crossSeconds
	while os.clock() - startClock < cross do
		local t = (os.clock() - startClock) / cross
		local x = -80 + t * 160
		shark:PivotTo(CFrame.new(x, 2.5 + math.sin(t * math.pi * 3) * 0.4, 8) * CFrame.Angles(0, math.pi / 2, 0))
		for _, player in Players:GetPlayers() do
			if alreadyHit[player] == nil then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(x, 0, 8)).Magnitude < 5 then
					alreadyHit[player] = true
					onHit(player)
				end
			end
		end
		task.wait(0.1)
	end
	shark:Destroy()
end

return Events
