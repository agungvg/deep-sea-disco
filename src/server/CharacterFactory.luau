--!strict
-- Deep Sea Disco: builds every critter as a part-based chibi dancer.
-- One design language for all 42: human-proportioned (2-3 heads tall),
-- two legs, two arms raised in a dance pose, a face that reads at 30 studs,
-- one creature feature (shape) and one signature prop (accessory).
-- Silhouette first: body masses, then face, then the prop. No detail that
-- only shows closer than the player ever stands.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Characters = require(Shared.Characters)
local Config = require(Shared.Config)

local CharacterFactory = {}

local function part(
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- The creature feature: a few parts that change the silhouette per shape.
local function addShapeFeature(model: Model, shape: string, body: Color3, accent: Color3, s: number)
	local head = model:FindFirstChild("Head") :: Part
	local torso = model:FindFirstChild("Torso") :: Part
	if shape == "Fish" or shape == "Dolphin" or shape == "Shark" or shape == "Whale" or shape == "Narwhal" then
		local tail = part("Tail", Enum.PartType.Wedge, Vector3.new(0.5 * s, 0.9 * s, 0.18 * s), accent, Enum.Material.SmoothPlastic)
		tail.CFrame = torso.CFrame * CFrame.new(0, 0.1 * s, 0.75 * s) * CFrame.Angles(0, math.rad(180), 0)
		tail.Parent = model
		local fin = part("Fin", Enum.PartType.Wedge, Vector3.new(0.16 * s, 0.7 * s, 0.7 * s), accent, Enum.Material.SmoothPlastic)
		fin.CFrame = torso.CFrame * CFrame.new(0, 0.75 * s, 0.1 * s)
		fin.Parent = model
		if shape == "Narwhal" then
			local horn = part("Horn", Enum.PartType.Cylinder, Vector3.new(0.18 * s, 1.1 * s, 0.18 * s), Color3.fromRGB(240, 230, 200), Enum.Material.SmoothPlastic)
			horn.CFrame = head.CFrame * CFrame.new(0, 0.9 * s, -0.45 * s) * CFrame.Angles(math.rad(70), 0, 0)
			horn.Parent = model
		end
	elseif shape == "Crab" or shape == "Lobster" then
		for _, side in { -1, 1 } do
			local claw = part("Claw", Enum.PartType.Ball, Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), body, Enum.Material.SmoothPlastic)
			claw.CFrame = torso.CFrame * CFrame.new(0.75 * side * s, 0.35 * s, -0.35 * s)
			claw.Parent = model
		end
	elseif shape == "Jelly" or shape == "Angler" then
		local dome = part("Dome", Enum.PartType.Ball, Vector3.new(1.5 * s, 0.9 * s, 1.5 * s), body, Enum.Material.SmoothPlastic)
		dome.CFrame = head.CFrame * CFrame.new(0, 0.45 * s, 0)
		dome.Transparency = 0.25
		dome.Parent = model
		for i = 1, 4 do
			local tentacle = part("Tentacle", Enum.PartType.Cylinder, Vector3.new(0.12 * s, 0.8 * s, 0.12 * s), accent, Enum.Material.SmoothPlastic)
			local angle = (i - 2.5) * 0.35
			tentacle.CFrame = torso.CFrame * CFrame.new(angle * s, -0.7 * s, 0.35 * s)
			tentacle.Parent = model
		end
		if shape == "Angler" then
			local lure = part("Lure", Enum.PartType.Ball, Vector3.new(0.28 * s, 0.28 * s, 0.28 * s), Config.LimeColor, Enum.Material.Neon)
			lure.CFrame = head.CFrame * CFrame.new(0, 0.9 * s, -0.7 * s)
			lure.Parent = model
		end
	elseif shape == "Star" then
		for i = 1, 5 do
			local angle = (i - 1) * (math.pi * 2 / 5)
			local arm = part("StarArm", Enum.PartType.Ball, Vector3.new(0.45 * s, 0.45 * s, 0.45 * s), body, Enum.Material.SmoothPlastic)
			arm.CFrame = torso.CFrame * CFrame.new(math.sin(angle) * 0.75 * s, 0.1 * s, math.cos(angle) * 0.75 * s)
			arm.Parent = model
		end
	elseif shape == "Squid" or shape == "Octopus" or shape == "Kraken" then
		for i = 1, 6 do
			local tentacle = part("Tentacle", Enum.PartType.Cylinder, Vector3.new(0.14 * s, 0.9 * s, 0.14 * s), body, Enum.Material.SmoothPlastic)
			local angle = (i - 3.5) * 0.4
			tentacle.CFrame = torso.CFrame * CFrame.new(angle * s, -0.75 * s, 0.3 * s) * CFrame.Angles(0, 0, angle * 0.4)
			tentacle.Parent = model
		end
	elseif shape == "Eel" or shape == "Whirl" or shape == "Wave" then
		for i = 1, 3 do
			local coil = part("Coil", Enum.PartType.Ball, Vector3.new(0.5 * s, 0.5 * s, 0.5 * s), body, Enum.Material.SmoothPlastic)
			coil.CFrame = torso.CFrame * CFrame.new((i - 2) * 0.45 * s, -0.55 * s - i * 0.15 * s, 0.25 * s)
			coil.Parent = model
		end
	elseif shape == "Manta" then
		local wing = part("Wing", Enum.PartType.Ball, Vector3.new(2.4 * s, 0.25 * s, 1.1 * s), body, Enum.Material.SmoothPlastic)
		wing.CFrame = torso.CFrame * CFrame.new(0, 0.35 * s, 0)
		wing.Parent = model
	elseif shape == "Clam" then
		local shell = part("Shell", Enum.PartType.Ball, Vector3.new(1.4 * s, 0.5 * s, 1.4 * s), Color3.fromRGB(220, 200, 240), Enum.Material.SmoothPlastic)
		shell.CFrame = head.CFrame * CFrame.new(0, 0.55 * s, 0)
		shell.Parent = model
	elseif shape == "Kelp" or shape == "Coral" or shape == "Anemone" then
		for i = 1, 3 do
			local frond = part("Frond", Enum.PartType.Cylinder, Vector3.new(0.16 * s, 1.0 * s, 0.16 * s), accent, Enum.Material.SmoothPlastic)
			frond.CFrame = head.CFrame * CFrame.new((i - 2) * 0.35 * s, 0.8 * s, 0) * CFrame.Angles(0, 0, (i - 2) * 0.25)
			frond.Parent = model
		end
	elseif shape == "Urchin" then
		for i = 1, 6 do
			local spike = part("Spike", Enum.PartType.Cylinder, Vector3.new(0.1 * s, 0.7 * s, 0.1 * s), accent, Enum.Material.SmoothPlastic)
			local angle = (i - 1) * (math.pi / 3)
			spike.CFrame = head.CFrame * CFrame.new(math.cos(angle) * 0.6 * s, 0.5 * s, math.sin(angle) * 0.6 * s) * CFrame.Angles(math.sin(angle) * 0.9, 0, math.cos(angle) * 0.9)
			spike.Parent = model
		end
	elseif shape == "Puffer" then
		for i = 1, 5 do
			local spike = part("Spike", Enum.PartType.Ball, Vector3.new(0.22 * s, 0.22 * s, 0.22 * s), accent, Enum.Material.SmoothPlastic)
			local angle = (i - 1) * (math.pi * 2 / 5)
			spike.CFrame = torso.CFrame * CFrame.new(math.sin(angle) * 0.8 * s, 0.2 * s, math.cos(angle) * 0.8 * s)
			spike.Parent = model
		end
	elseif shape == "Merfolk" or shape == "Trench" or shape == "Vent" then
		local tail = part("Tail", Enum.PartType.Wedge, Vector3.new(0.9 * s, 1.0 * s, 0.3 * s), accent, Enum.Material.SmoothPlastic)
		tail.CFrame = torso.CFrame * CFrame.new(0, -0.9 * s, 0.15 * s) * CFrame.Angles(0, math.rad(180), 0)
		tail.Parent = model
	end
end

-- The signature prop: one chunk that breaks the silhouette on purpose.
local function addProp(model: Model, prop: string, accent: Color3, s: number)
	local head = model:FindFirstChild("Head") :: Part
	if prop == "DiscoBall" then
		local ball = part("DiscoBall", Enum.PartType.Ball, Vector3.new(0.7 * s, 0.7 * s, 0.7 * s), Color3.fromRGB(210, 210, 220), Enum.Material.Metal)
		ball.CFrame = head.CFrame * CFrame.new(0, 0.85 * s, 0)
		ball.Parent = model
	elseif prop == "Headphones" then
		local band = part("Band", Enum.PartType.Cylinder, Vector3.new(0.16 * s, 1.3 * s, 0.16 * s), accent, Enum.Material.SmoothPlastic)
		band.CFrame = head.CFrame * CFrame.new(0, 0.35 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
		band.Parent = model
		for _, side in { -1, 1 } do
			local cup = part("Cup", Enum.PartType.Ball, Vector3.new(0.4 * s, 0.4 * s, 0.4 * s), accent, Enum.Material.SmoothPlastic)
			cup.CFrame = head.CFrame * CFrame.new(0.65 * side * s, 0.1 * s, 0)
			cup.Parent = model
		end
	elseif prop == "Sunglasses" then
		for _, side in { -1, 1 } do
			local lens = part("Lens", Enum.PartType.Block, Vector3.new(0.42 * s, 0.3 * s, 0.1 * s), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic)
			lens.CFrame = head.CFrame * CFrame.new(0.26 * side * s, 0.15 * s, -0.52 * s)
			lens.Parent = model
		end
	elseif prop == "Crown" then
		local crown = part("Crown", Enum.PartType.Cylinder, Vector3.new(0.9 * s, 0.35 * s, 0.9 * s), Color3.fromRGB(255, 201, 60), Enum.Material.Metal)
		crown.CFrame = head.CFrame * CFrame.new(0, 0.8 * s, 0)
		crown.Parent = model
	elseif prop == "TopHat" then
		local hat = part("TopHat", Enum.PartType.Cylinder, Vector3.new(0.7 * s, 0.7 * s, 0.7 * s), Color3.fromRGB(30, 30, 45), Enum.Material.SmoothPlastic)
		hat.CFrame = head.CFrame * CFrame.new(0, 0.9 * s, 0)
		hat.Parent = model
	elseif prop == "Bowtie" then
		local bow = part("Bowtie", Enum.PartType.Wedge, Vector3.new(0.5 * s, 0.3 * s, 0.12 * s), accent, Enum.Material.SmoothPlastic)
		bow.CFrame = (model:FindFirstChild("Torso") :: Part).CFrame * CFrame.new(0, 0.55 * s, -0.45 * s)
		bow.Parent = model
	elseif prop == "Flower" then
		local flower = part("Flower", Enum.PartType.Ball, Vector3.new(0.4 * s, 0.4 * s, 0.4 * s), accent, Enum.Material.SmoothPlastic)
		flower.CFrame = head.CFrame * CFrame.new(0.55 * s, 0.65 * s, 0)
		flower.Parent = model
	elseif prop == "Trident" then
		local staff = part("Trident", Enum.PartType.Cylinder, Vector3.new(0.12 * s, 2.2 * s, 0.12 * s), Color3.fromRGB(255, 201, 60), Enum.Material.Metal)
		staff.CFrame = (model:FindFirstChild("Torso") :: Part).CFrame * CFrame.new(0.9 * s, 0.3 * s, -0.2 * s)
		staff.Parent = model
	elseif prop == "GlowRing" then
		local ring = part("GlowRing", Enum.PartType.Cylinder, Vector3.new(1.5 * s, 0.12 * s, 1.5 * s), Config.LimeColor, Enum.Material.Neon)
		ring.CFrame = (model:FindFirstChild("Torso") :: Part).CFrame * CFrame.new(0, -0.2 * s, 0) * CFrame.Angles(math.rad(90), 0, 0)
		ring.Parent = model
	end
end

-- Face: big eyes, blush, smile. Reads at 30 studs, nothing smaller.
local function addFace(model: Model, s: number)
	local head = model:FindFirstChild("Head") :: Part
	for _, side in { -1, 1 } do
		local eye = part("Eye", Enum.PartType.Ball, Vector3.new(0.3 * s, 0.38 * s, 0.12 * s), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		eye.CFrame = head.CFrame * CFrame.new(0.26 * side * s, 0.18 * s, -0.52 * s)
		eye.Parent = model
		local pupil = part("Pupil", Enum.PartType.Ball, Vector3.new(0.16 * s, 0.2 * s, 0.08 * s), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic)
		pupil.CFrame = head.CFrame * CFrame.new(0.26 * side * s, 0.16 * s, -0.58 * s)
		pupil.Parent = model
		local blush = part("Blush", Enum.PartType.Ball, Vector3.new(0.22 * s, 0.14 * s, 0.08 * s), Color3.fromRGB(255, 150, 150), Enum.Material.SmoothPlastic)
		blush.CFrame = head.CFrame * CFrame.new(0.48 * side * s, -0.12 * s, -0.5 * s)
		blush.Parent = model
	end
	local mouth = part("Mouth", Enum.PartType.Block, Vector3.new(0.34 * s, 0.08 * s, 0.08 * s), Color3.fromRGB(60, 30, 30), Enum.Material.SmoothPlastic)
	mouth.CFrame = head.CFrame * CFrame.new(0, -0.28 * s, -0.54 * s)
	mouth.Parent = model
end

-- Floating label: name + rarity + $/s. AlwaysOnTop so the judge can read it.
function CharacterFactory.addLabel(model: Model, def: Characters.CritterDef)
	local tierColor = Config.Tiers[def.tier].color
	local gui = Instance.new("BillboardGui")
	gui.Name = "CritterLabel"
	gui.Size = UDim2.fromOffset(150, 58)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4 * def.size, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local head = model:FindFirstChild("Head")
	gui.Parent = head or model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.42, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.1
	nameLabel.Parent = gui

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Position = UDim2.new(0, 0, 0.42, 0)
	tierLabel.Size = UDim2.new(1, 0, 0.28, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = string.upper(def.tier)
	tierLabel.Font = Enum.Font.FredokaOne
	tierLabel.TextScaled = true
	tierLabel.TextColor3 = tierColor
	tierLabel.TextStrokeTransparency = 0.1
	tierLabel.Parent = gui

	local earnLabel = Instance.new("TextLabel")
	earnLabel.Position = UDim2.new(0, 0, 0.7, 0)
	earnLabel.Size = UDim2.new(1, 0, 0.3, 0)
	earnLabel.BackgroundTransparency = 1
	earnLabel.Text = "+$" .. tostring(def.earn) .. "/s"
	earnLabel.Font = Enum.Font.FredokaOne
	earnLabel.TextScaled = true
	earnLabel.TextColor3 = Config.LimeColor
	earnLabel.TextStrokeTransparency = 0.1
	earnLabel.Parent = gui
end

-- Build one critter model at a position, facing a yaw. Anchored; the server
-- bobs it with PivotTo on a heartbeat so it is never in a dead-neutral pose.
function CharacterFactory.build(def: Characters.CritterDef, position: Vector3, yaw: number): Model
	local s = def.size
	local model = Instance.new("Model")
	model.Name = def.id

	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local torso = part("Torso", Enum.PartType.Ball, Vector3.new(1.1 * s, 1.2 * s, 0.85 * s), def.body, Enum.Material.SmoothPlastic)
	torso.CFrame = base * CFrame.new(0, 1.55 * s, 0)
	torso.Parent = model
	model.PrimaryPart = torso

	local head = part("Head", Enum.PartType.Ball, Vector3.new(1.05 * s, 1.0 * s, 0.95 * s), def.body, Enum.Material.SmoothPlastic)
	head.CFrame = base * CFrame.new(0, 2.55 * s, 0) * CFrame.Angles(0, 0, math.rad(-6))
	head.Parent = model

	-- Dance pose: left arm up, right arm out, one leg bent.
	local leftArm = part("LeftArm", Enum.PartType.Cylinder, Vector3.new(0.3 * s, 1.0 * s, 0.3 * s), def.body, Enum.Material.SmoothPlastic)
	leftArm.CFrame = base * CFrame.new(-0.75 * s, 2.1 * s, -0.15 * s) * CFrame.Angles(math.rad(-35), 0, math.rad(55))
	leftArm.Parent = model
	local rightArm = part("RightArm", Enum.PartType.Cylinder, Vector3.new(0.3 * s, 1.0 * s, 0.3 * s), def.body, Enum.Material.SmoothPlastic)
	rightArm.CFrame = base * CFrame.new(0.75 * s, 1.85 * s, -0.2 * s) * CFrame.Angles(math.rad(-70), 0, math.rad(-35))
	rightArm.Parent = model
	local leftLeg = part("LeftLeg", Enum.PartType.Cylinder, Vector3.new(0.34 * s, 0.9 * s, 0.34 * s), def.accent, Enum.Material.SmoothPlastic)
	leftLeg.CFrame = base * CFrame.new(-0.3 * s, 0.55 * s, 0.1 * s) * CFrame.Angles(math.rad(18), 0, math.rad(6))
	leftLeg.Parent = model
	local rightLeg = part("RightLeg", Enum.PartType.Cylinder, Vector3.new(0.34 * s, 0.9 * s, 0.34 * s), def.accent, Enum.Material.SmoothPlastic)
	rightLeg.CFrame = base * CFrame.new(0.3 * s, 0.55 * s, -0.12 * s) * CFrame.Angles(math.rad(-12), 0, math.rad(-6))
	rightLeg.Parent = model

	addFace(model, s)
	addShapeFeature(model, def.shape, def.body, def.accent, s)
	addProp(model, def.prop, def.accent, s)
	CharacterFactory.addLabel(model, def)
	return model
end

return CharacterFactory
