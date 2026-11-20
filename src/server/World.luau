--!strict
-- Deep Sea Disco: builds the whole 3D world from code, so the place file
-- Rojo builds is the whole game and Studio is never the source of truth.
-- Layout: a sand seabed, the Open Water spawning field to the north, a
-- coral dance floor in the middle, six player bases ringing it, and the
-- trench portal to the south where the Net Nabber escapes.
-- Materials carry the look: sand underfoot, smooth stone on the floor,
-- coral and kelp as accents, neon only on things that glow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local World = {}

export type BaseSpot = {
	index: number,
	center: Vector3,
	angle: number,
}

function World.baseSpots(): { BaseSpot }
	local spots = {}
	for i = 1, Config.BaseCount do
		local angle = (i - 1) * (math.pi * 2 / Config.BaseCount) - math.pi / 2
		local x = math.cos(angle) * Config.BaseRadius
		local z = math.sin(angle) * Config.BaseRadius + 10
		table.insert(spots, { index = i, center = Vector3.new(x, 0, z), angle = angle })
	end
	return spots
end

local function part(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function buildLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(10, 45, 55)
	lighting.OutdoorAmbient = Color3.fromRGB(20, 70, 85)
	lighting.Brightness = 1.6
	lighting.ClockTime = 13
	lighting.FogColor = Color3.fromRGB(6, 42, 51)
	lighting.FogEnd = 320
	lighting.GeographicLatitude = 20

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(30, 110, 120)
	atmosphere.Decay = Color3.fromRGB(10, 50, 60)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.5
	atmosphere.Parent = lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 0.85
	bloom.Parent = lighting

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Contrast = 0.08
	grade.Saturation = 0.05
	grade.TintColor = Color3.fromRGB(235, 250, 245)
	grade.Parent = lighting
end

local function buildSeabed(parent: Instance)
	local floor = part("Seabed", Vector3.new(240, 2, 240), Vector3.new(0, -1, 0), Config.SandColor, Enum.Material.Sand)
	floor.Parent = parent

	-- The Open Water: darker sand where critters spawn, marked by kelp.
	local water = part("OpenWater", Vector3.new(150, 0.4, 55), Vector3.new(0, 0.2, -33), Color3.fromRGB(30, 90, 100), Enum.Material.SmoothPlastic)
	water.CanCollide = false
	water.Parent = parent
	local sign = part("OpenWaterSign", Vector3.new(24, 4, 0.6), Vector3.new(0, 6, -62), Config.PanelColor, Enum.Material.SmoothPlastic)
	sign.Parent = parent
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "OPEN WATER"
	signText.Font = Enum.Font.FredokaOne
	signText.TextScaled = true
	signText.TextColor3 = Config.LimeColor
	signText.Parent = signGui

	-- The dance floor: checkered stone, coral trim.
	for gx = -3, 3 do
		for gz = -3, 3 do
			local light = (gx + gz) % 2 == 0
			local tile = part(
				"DanceTile",
				Vector3.new(6, 0.5, 6),
				Vector3.new(gx * 6, 0.25, 8 + gz * 6),
				if light then Color3.fromRGB(46, 196, 182) else Color3.fromRGB(18, 60, 72),
				Enum.Material.Slate
			)
			tile.CanCollide = false
			tile.Parent = parent
		end
	end
end

local function buildDiscoBall(parent: Instance)
	local pole = part("DiscoPole", Vector3.new(0.6, 18, 0.6), Vector3.new(0, 9, 8), Color3.fromRGB(120, 120, 130), Enum.Material.Metal)
	pole.Parent = parent
	local ball = part("DiscoBall", Vector3.new(7, 7, 7), Vector3.new(0, 20, 8), Color3.fromRGB(220, 220, 230), Enum.Material.Metal, Enum.PartType.Ball)
	ball.Parent = parent
	local glow = Instance.new("PointLight")
	glow.Color = Config.CoralColor
	glow.Brightness = 1.4
	glow.Range = 40
	glow.Shadows = false
	glow.Parent = ball
	local warm = Instance.new("PointLight")
	warm.Color = Color3.fromRGB(255, 201, 60)
	warm.Brightness = 0.6
	warm.Range = 55
	warm.Shadows = false
	warm.Position = Vector3.new(0, 14, 8)
	warm.Parent = parent
end

local function buildTrenchPortal(parent: Instance)
	local frame = part("TrenchFrame", Vector3.new(16, 12, 1.5), Vector3.new(0, 6, 96), Color3.fromRGB(40, 40, 60), Enum.Material.Slate)
	frame.Parent = parent
	local mouth = part("TrenchMouth", Vector3.new(12, 9, 0.6), Vector3.new(0, 5.5, 95), Color3.fromRGB(10, 10, 25), Enum.Material.Neon)
	mouth.CanCollide = false
	mouth.Parent = parent
	local ring = part("TrenchRing", Vector3.new(14, 1, 1), Vector3.new(0, 11.5, 95), Config.LimeColor, Enum.Material.Neon)
	ring.CanCollide = false
	ring.Parent = parent
end

local function buildDecor(parent: Instance, rng: Random)
	-- Coral clusters and kelp, scattered where they never block a base.
	local spots = {
		Vector3.new(-55, 0, -45), Vector3.new(55, 0, -48), Vector3.new(-40, 0, 55),
		Vector3.new(48, 0, 58), Vector3.new(-70, 0, 10), Vector3.new(70, 0, -5),
		Vector3.new(-25, 0, -55), Vector3.new(28, 0, -52), Vector3.new(-60, 0, 35),
		Vector3.new(62, 0, 30),
	}
	for i, spot in spots do
		local coral = part("Coral", Vector3.new(2.5, 3 + rng:NextNumber(0, 3), 2.5), spot + Vector3.new(0, 2, 0), Config.CoralColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		coral.Parent = parent
		local kelp = part("Kelp", Vector3.new(0.7, 7 + rng:NextNumber(0, 4), 0.7), spot + Vector3.new(3, 4, 1), Color3.fromRGB(70, 180, 110), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		kelp.Parent = parent
		_ = i
	end
	-- Bubbles rising: a few anchored neon spheres that the server drifts up.
	for i = 1, 10 do
		local bubble = part("Bubble", Vector3.new(0.9, 0.9, 0.9), Vector3.new(rng:NextNumber(-60, 60), rng:NextNumber(2, 14), rng:NextNumber(-50, 60)), Color3.fromRGB(180, 240, 240), Enum.Material.Glass, Enum.PartType.Ball)
		bubble.CanCollide = false
		bubble.Transparency = 0.4
		bubble.Parent = parent
		_ = i
	end
end

-- Build the world into Workspace. Returns the base spots for Bases to claim.
function World.build(): { BaseSpot }
	buildLighting()
	local rng = Random.new(20261120)
	local folder = Instance.new("Folder")
	folder.Name = "DeepSeaDiscoWorld"
	folder.Parent = workspace
	buildSeabed(folder)
	buildDiscoBall(folder)
	buildTrenchPortal(folder)
	buildDecor(folder, rng)
	return World.baseSpots()
end

return World
