--!strict
-- Deep Sea Disco: player bases. Six plots ring the dance floor; the first
-- player to arrive claims a free one. Each base has a floor, a back wall
-- with the owner's name, a deposit pad, and dance pedestals that fill as
-- the owner deposits critters. Pedestals show a price tag while empty.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)

local Bases = {}

export type Base = {
	spotIndex: number,
	center: Vector3,
	angle: number,
	owner: Player?,
	folder: Folder,
	pedestals: { Pedestal },
	pad: Part,
}

export type Pedestal = {
	part: Part,
	priceTag: BillboardGui,
	occupiedBy: string?, -- critter uid on this pedestal, or nil
}

local bases: { Base } = {}

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
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function priceTag(parent: Part, text: string): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "PriceTag"
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Price"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Config.PanelColor
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Config.LimeColor
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return gui
end

local function buildOne(spot: { index: number, center: Vector3, angle: number }, parent: Instance): Base
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(spot.index)
	folder.Parent = parent

	local c = spot.center
	local rot = CFrame.new(c) * CFrame.Angles(0, -spot.angle + math.pi / 2, 0)
	local floor = part("Floor", Vector3.new(20, 1, 16), Vector3.new(c.X, 0.5, c.Z), Config.SandDark, Enum.Material.WoodPlanks)
	floor.Parent = folder
	local wall = part("Wall", Vector3.new(20, 7, 1), Vector3.new(0, 0, 0), Config.PanelColor, Enum.Material.SmoothPlastic)
	wall.CFrame = rot * CFrame.new(0, 3.5, 7.5)
	wall.Parent = folder

	local nameGui = Instance.new("SurfaceGui")
	nameGui.Face = Enum.NormalId.Front
	nameGui.Parent = wall
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "OwnerLabel"
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "OPEN BASE"
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Config.CoralColor
	nameLabel.Parent = nameGui

	-- Deposit pad: stepping here with a carried critter deposits it.
	local pad = part("DepositPad", Vector3.new(5, 0.4, 5), Vector3.new(c.X, 0.2, c.Z), Config.TealColor, Enum.Material.Neon)
	pad.CanCollide = false
	pad.Parent = folder
	local padPrompt = Instance.new("ProximityPrompt")
	padPrompt.ActionText = "Deposit critter"
	padPrompt.ObjectText = "Dance pedestal"
	padPrompt.KeyboardKeyCode = Enum.KeyCode.E
	padPrompt.HoldDuration = 0
	padPrompt.MaxActivationDistance = 6
	padPrompt.Parent = pad

	-- Pedestals in two rows of two (more appear with the Base Slots upgrade).
	local pedestals: { Pedestal } = {}
	local offsets = {
		Vector3.new(-6, 0, -4), Vector3.new(6, 0, -4),
		Vector3.new(-6, 0, 4), Vector3.new(6, 0, 4),
	}
	for i, off in offsets do
		local worldOff = rot * off
		local ped = part("Pedestal", Vector3.new(4, 1, 4), Vector3.new(c.X + worldOff.X, 0.5, c.Z + worldOff.Z), Color3.fromRGB(220, 220, 230), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		ped.Parent = folder
		local tag = priceTag(ped, "$0")
		table.insert(pedestals, { part = ped, priceTag = tag, occupiedBy = nil })
		_ = i
	end

	local base: Base = {
		spotIndex = spot.index,
		center = c,
		angle = spot.angle,
		owner = nil,
		folder = folder,
		pedestals = pedestals,
		pad = pad,
	}
	return base
end

-- Build all bases from the world's spots. Returns the list, unclaimed.
function Bases.build(spots: { { index: number, center: Vector3, angle: number } }): { Base }
	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	folder.Parent = workspace
	for _, spot in spots do
		table.insert(bases, buildOne(spot, folder))
	end
	return bases
end

function Bases.all(): { Base }
	return bases
end

-- Claim the first free base for a player. Returns nil when the map is full.
function Bases.claimFor(player: Player): Base?
	for _, base in bases do
		if base.owner == nil then
			base.owner = player
			local wall = base.folder:FindFirstChild("Wall") :: Part
			local gui = wall:FindFirstChildOfClass("SurfaceGui")
			if gui then
				local label = gui:FindFirstChild("OwnerLabel") :: TextLabel
				label.Text = string.upper(player.Name) .. "'S DISCO"
				label.TextColor3 = Config.LimeColor
			end
			return base
		end
	end
	return nil
end

function Bases.of(player: Player): Base?
	for _, base in bases do
		if base.owner == player then
			return base
		end
	end
	return nil
end

function Bases.release(player: Player)
	local base = Bases.of(player)
	if base then
		base.owner = nil
		local wall = base.folder:FindFirstChild("Wall") :: Part
		local gui = wall:FindFirstChildOfClass("SurfaceGui")
		if gui then
			local label = gui:FindFirstChild("OwnerLabel") :: TextLabel
			label.Text = "OPEN BASE"
			label.TextColor3 = Config.CoralColor
		end
	end
end

-- First pedestal with no critter on it, or nil when the base is full.
function Bases.freePedestal(base: Base): Pedestal?
	for _, ped in base.pedestals do
		if ped.occupiedBy == nil then
			return ped
		end
	end
	return nil
end

-- Grow the base by two pedestals (Base Slots upgrade), up to 10.
function Bases.addPedestals(base: Base, count: number)
	local existing = #base.pedestals
	if existing >= 10 then
		return
	end
	local rot = CFrame.new(base.center) * CFrame.Angles(0, -base.angle + math.pi / 2, 0)
	local extraOffsets = {
		Vector3.new(-6, 0, -8), Vector3.new(6, 0, -8),
		Vector3.new(-6, 0, 8), Vector3.new(6, 0, 8),
		Vector3.new(0, 0, -8), Vector3.new(0, 0, 8),
	}
	for i = 1, math.min(count, 10 - existing) do
		local off = extraOffsets[existing + i - 1] or Vector3.new(0, 0, 0)
		local worldOff = rot * off
		local ped = part("Pedestal", Vector3.new(4, 1, 4), Vector3.new(base.center.X + worldOff.X, 0.5, base.center.Z + worldOff.Z), Color3.fromRGB(220, 220, 230), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		ped.Parent = base.folder
		local tag = priceTag(ped, "$0")
		table.insert(base.pedestals, { part = ped, priceTag = tag, occupiedBy = nil })
	end
end

-- The pedestal's price tag shows what the critter on it earns.
function Bases.setPedestalTag(ped: Pedestal, earnPerSecond: number)
	local label = ped.priceTag:FindFirstChild("Price") :: TextLabel
	label.Text = "$" .. Format.withCommas(earnPerSecond) .. "/s"
end

function Bases.clearPedestalTag(ped: Pedestal)
	local label = ped.priceTag:FindFirstChild("Price") :: TextLabel
	label.Text = "$0"
end

return Bases
