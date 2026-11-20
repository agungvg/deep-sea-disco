--!strict
-- Deep Sea Disco: the Net Nabber. A thief crab NPC spawns at the trench
-- portal, scuttles to a random unlocked base, steals one critter off its
-- pedestal, and flees back toward the portal. Tag him (touch him) before
-- he escapes and the critter goes straight back to its pedestal.
-- The server owns the crab, the steal, and the return; the client only
-- shows the banner and the burst.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Characters = require(Shared.Characters)

local ThiefAI = {}

export type StolenCritter = {
	uid: string,
	defId: string,
}

local crab: Model? = nil
local stolen: StolenCritter? = nil
local victim: Player? = nil
local running = false
local escapeDeadline = 0

local function buildCrab(position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "NetNabber"
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Shape = Enum.PartType.Ball
	torso.Size = Vector3.new(2.4, 1.4, 2.0)
	torso.Color = Color3.fromRGB(230, 70, 50)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = false
	torso.CFrame = CFrame.new(position)
	torso.Parent = model
	model.PrimaryPart = torso
	for _, side in { -1, 1 } do
		local claw = Instance.new("Part")
		claw.Name = "Claw"
		claw.Shape = Enum.PartType.Ball
		claw.Size = Vector3.new(1.0, 1.0, 1.0)
		claw.Color = Color3.fromRGB(255, 122, 89)
		claw.Material = Enum.Material.SmoothPlastic
		claw.Anchored = true
		claw.CanCollide = false
		claw.CFrame = CFrame.new(position + Vector3.new(1.5 * side, 0.2, -0.8))
		claw.Parent = model
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.35, 0.35, 0.35)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.CFrame = CFrame.new(position + Vector3.new(0.5 * side, 0.9, -0.9))
		eye.Parent = model
	end
	local net = Instance.new("Part")
	net.Name = "Net"
	net.Shape = Enum.PartType.Ball
	net.Size = Vector3.new(1.2, 1.2, 1.2)
	net.Color = Color3.fromRGB(184, 230, 46)
	net.Material = Enum.Material.Neon
	net.Anchored = true
	net.CanCollide = false
	net.Transparency = 0.4
	net.CFrame = CFrame.new(position + Vector3.new(0, 1.2, 0.5))
	net.Parent = model
	return model
end

-- Move the crab toward a target at a steady speed. Returns false if it
-- was caught mid-trip (the caller checks running).
local function scuttleTo(target: Vector3, speed: number): boolean
	local current = crab
	if current == nil or current.PrimaryPart == nil then
		return false
	end
	while running do
		local root = current.PrimaryPart :: Part
		local here = root.Position
		local flat = Vector3.new(target.X - here.X, 0, target.Z - here.Z)
		if flat.Magnitude < 2 then
			return true
		end
		local step = flat.Unit * math.min(speed * 0.15, flat.Magnitude)
		local next = here + step
		current:PivotTo(CFrame.new(next.X, 1.2, next.Z) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0))
		task.wait(0.15)
	end
	return false
end

-- Run one nab: pick a victim base, steal, flee. onStolen / onReturned /
-- onEscaped are GameServer callbacks that move the real critter record.
function ThiefAI.run(
	pickVictim: () -> (Player?, StolenCritter?),
	onReturned: (Player, StolenCritter) -> (),
	onEscaped: (Player, StolenCritter) -> (),
	announce: (string, string) -> ()
)
	if running then
		return
	end
	running = true
	local targetPlayer, critter = pickVictim()
	if targetPlayer == nil or critter == nil then
		running = false
		return
	end
	victim = targetPlayer
	stolen = critter
	local def = Characters.ById[critter.defId]

	announce("NET NABBER!", "A thief crab is coming for " .. def.name .. "!")

	crab = buildCrab(Vector3.new(0, 1.2, 92))
	crab.Parent = workspace
	local folder = crab :: Model

	-- Touch to tag: any player who touches the crab gets the critter back.
	local touchPart = folder.PrimaryPart :: Part
	local caught = false
	local connection
	connection = touchPart.Touched:Connect(function(hit: BasePart)
		if caught or not running then
			return
		end
		local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if player == nil then
			return
		end
		caught = true
		local v = victim
		local s = stolen
		running = false
		if connection then
			connection:Disconnect()
		end
		if folder.Parent ~= nil then
			folder:Destroy()
		end
		crab = nil
		if v ~= nil and s ~= nil then
			onReturned(v, s)
			announce("CAUGHT HIM!", player.Name .. " tagged the Net Nabber — " .. Characters.ById[s.defId].name .. " is safe!")
		end
	end)

	-- Scuttle to the victim's base, then flee to the portal.
	local bases = workspace:FindFirstChild("Bases")
	local baseFolder: Instance? = nil
	if bases then
		for _, child in bases:GetChildren() do
			local wall = child:FindFirstChild("Wall")
			if wall then
				local gui = wall:FindFirstChildOfClass("SurfaceGui")
				if gui then
					local label = gui:FindFirstChild("OwnerLabel") :: TextLabel
					if label and string.find(label.Text, string.upper(targetPlayer.Name)) then
						baseFolder = child
						break
					end
				end
			end
		end
	end
	local dest = Vector3.new(0, 1.2, 92)
	if baseFolder then
		local floor = (baseFolder :: Folder):FindFirstChild("Floor") :: Part
		if floor then
			dest = floor.Position
		end
	end
	if not caught and scuttleTo(dest, 7) then
		announce("HE GRABBED IT!", "The Net Nabber stole " .. def.name .. " — tag him before the portal!")
		escapeDeadline = os.clock() + Config.Events.NetNabber.escapeSeconds
		local escaped = scuttleTo(Vector3.new(0, 1.2, 92), 9)
		if escaped and not caught and running then
			running = false
			if connection then
				connection:Disconnect()
			end
			if folder.Parent ~= nil then
				folder:Destroy()
			end
			crab = nil
			local v = victim
			local s = stolen
			if v ~= nil and s ~= nil then
				onEscaped(v, s)
				announce("HE ESCAPED!", "The Net Nabber vanished into the trench with " .. Characters.ById[s.defId].name .. "!")
			end
		end
	end

	if connection then
		connection:Disconnect()
	end
	if crab ~= nil and crab.Parent ~= nil then
		crab:Destroy()
	end
	crab = nil
	running = false
end

function ThiefAI.isRunning(): boolean
	return running
end

function ThiefAI.timeLeft(): number
	if not running then
		return 0
	end
	return math.max(0, escapeDeadline - os.clock())
end

return ThiefAI
