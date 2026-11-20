--!strict
-- Deep Sea Disco: the HUD. Built from code so the place file is the whole
-- game. Top-center: the Bubbles counter with +$/s underneath and the
-- multiplier pill beside it. Right: the button stack — UPGRADES, INDEX,
-- DROP THE BEAT, GO DARK. Bottom: the one-line hint. The server sends
-- state; this script only renders it. Never trust the client with money.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Characters = require(Shared.Characters)
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdate = Remotes:WaitForChild("StateUpdate") :: RemoteEvent
local JuiceEvent = Remotes:WaitForChild("Juice") :: RemoteEvent
local RequestBuyUpgrade = Remotes:WaitForChild("RequestBuyUpgrade") :: RemoteEvent
local RequestLock = Remotes:WaitForChild("RequestLock") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "DeepSeaDiscoHud"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeButton(parent: Instance, name: string, text: string, color: Color3, y: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, y)
	button.Size = UDim2.new(0, 230, 0, 52)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.15
	button.Parent = parent
	corner(button, 12)
	return button
end

-- Top-center money pill (clear of the top-left Roblox menu buttons).
local moneyPill = Instance.new("Frame")
moneyPill.Name = "MoneyPill"
moneyPill.AnchorPoint = Vector2.new(0.5, 0)
moneyPill.Position = UDim2.new(0.5, 0, 12, 0)
moneyPill.Size = UDim2.new(0, 300, 0, 76)
moneyPill.BackgroundColor3 = Config.PanelColor
moneyPill.BorderSizePixel = 0
moneyPill.Parent = screen
corner(moneyPill, 16)
local moneyStroke = Instance.new("UIStroke")
moneyStroke.Color = Config.TealColor
moneyStroke.Thickness = 2
moneyStroke.Parent = moneyPill

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "Bubbles"
moneyLabel.Size = UDim2.new(1, 0, 0.58, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "$0"
moneyLabel.Font = Enum.Font.FredokaOne
moneyLabel.TextScaled = true
moneyLabel.TextColor3 = Config.LimeColor
moneyLabel.Parent = moneyPill

local rateLabel = Instance.new("TextLabel")
rateLabel.Name = "Rate"
rateLabel.Position = UDim2.new(0, 0, 0.58, 0)
rateLabel.Size = UDim2.new(1, 0, 0.42, 0)
rateLabel.BackgroundTransparency = 1
rateLabel.Text = "+$0/s"
rateLabel.Font = Enum.Font.FredokaOne
rateLabel.TextScaled = true
rateLabel.TextColor3 = Config.GoldColor
rateLabel.Parent = moneyPill

-- Multiplier pill, right of the money pill.
local multPill = Instance.new("TextButton")
multPill.Name = "Multiplier"
multPill.AnchorPoint = Vector2.new(0, 0)
multPill.Position = UDim2.new(0.5, 168, 12, 0)
multPill.Size = UDim2.new(0, 130, 0, 52)
multPill.BackgroundColor3 = Config.CoralColor
multPill.BorderSizePixel = 0
multPill.Text = "x1 MONEY"
multPill.Font = Enum.Font.FredokaOne
multPill.TextScaled = true
multPill.TextColor3 = Color3.fromRGB(255, 255, 255)
multPill.Parent = screen
corner(multPill, 12)

-- Game title, top-right, above the button stack.
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.AnchorPoint = Vector2.new(1, 0)
titleLabel.Position = UDim2.new(1, -16, 0, 76)
titleLabel.Size = UDim2.new(0, 230, 0, 44)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "DEEP SEA DISCO"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextScaled = true
titleLabel.TextColor3 = Config.TealColor
titleLabel.TextStrokeTransparency = 0.1
titleLabel.Parent = screen

-- Right-side button stack.
local upgradesButton = makeButton(screen, "UpgradesButton", "UPGRADES", Color3.fromRGB(60, 120, 220), 132)
local indexButton = makeButton(screen, "IndexButton", "INDEX 0/42", Color3.fromRGB(150, 100, 220), 192)
local beatButton = makeButton(screen, "BeatButton", "DROP THE BEAT", Config.CoralColor, 252)
local darkButton = makeButton(screen, "DarkButton", "GO DARK", Color3.fromRGB(200, 50, 50), 312)

-- Bottom hint bar.
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "Hint"
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -14)
hintLabel.Size = UDim2.new(0, 640, 0, 34)
hintLabel.BackgroundColor3 = Config.PanelColor
hintLabel.BackgroundTransparency = 0.25
hintLabel.BorderSizePixel = 0
hintLabel.Text = "Catch a critter in the Open Water, carry it home, press E to deposit!"
hintLabel.Font = Enum.Font.FredokaOne
hintLabel.TextScaled = true
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hintLabel.Parent = screen
corner(hintLabel, 10)

-- Fever timer, under the money pill, shown only during Disco Fever.
local feverLabel = Instance.new("TextLabel")
feverLabel.Name = "Fever"
feverLabel.AnchorPoint = Vector2.new(0.5, 0)
feverLabel.Position = UDim2.new(0.5, 0, 96, 0)
feverLabel.Size = UDim2.new(0, 320, 0, 34)
feverLabel.BackgroundTransparency = 1
feverLabel.Text = ""
feverLabel.Font = Enum.Font.FredokaOne
feverLabel.TextScaled = true
feverLabel.TextColor3 = Config.CoralColor
feverLabel.Visible = false
feverLabel.Parent = screen

-- Index panel: the full 42 grid, 6 tiers x 7.
local indexPanel = Instance.new("Frame")
indexPanel.Name = "IndexPanel"
indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
indexPanel.Size = UDim2.new(0, 860, 0, 560)
indexPanel.BackgroundColor3 = Config.PanelColor
indexPanel.BorderSizePixel = 0
indexPanel.Visible = false
indexPanel.Parent = screen
corner(indexPanel, 16)

local indexTitle = Instance.new("TextLabel")
indexTitle.Size = UDim2.new(1, -70, 0, 52)
indexTitle.Position = UDim2.new(0, 20, 0, 8)
indexTitle.BackgroundTransparency = 1
indexTitle.Text = "INDEX 0/42"
indexTitle.Font = Enum.Font.FredokaOne
indexTitle.TextScaled = true
indexTitle.TextXAlignment = Enum.TextXAlignment.Left
indexTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
indexTitle.Parent = indexPanel

local indexClose = Instance.new("TextButton")
indexClose.AnchorPoint = Vector2.new(1, 0)
indexClose.Position = UDim2.new(1, -12, 0, 10)
indexClose.Size = UDim2.new(0, 44, 0, 44)
indexClose.BackgroundColor3 = Config.CoralColor
indexClose.Text = "X"
indexClose.Font = Enum.Font.FredokaOne
indexClose.TextScaled = true
indexClose.TextColor3 = Color3.fromRGB(255, 255, 255)
indexClose.Parent = indexPanel
corner(indexClose, 10)

local indexGrid = Instance.new("Frame")
indexGrid.Position = UDim2.new(0, 16, 0, 66)
indexGrid.Size = UDim2.new(1, -32, 1, -82)
indexGrid.BackgroundTransparency = 1
indexGrid.Parent = indexPanel
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 112, 0, 66)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.Parent = indexGrid

local indexCells: { [string]: TextLabel } = {}
for _, def in Characters.List do
	local cell = Instance.new("TextLabel")
	cell.Name = def.id
	cell.BackgroundColor3 = Color3.fromRGB(24, 58, 74)
	cell.BorderSizePixel = 0
	cell.Text = def.name .. "\n???\n+$" .. tostring(def.earn) .. "/s"
	cell.Font = Enum.Font.FredokaOne
	cell.TextScaled = true
	cell.TextColor3 = Color3.fromRGB(140, 160, 170)
	cell.Parent = indexGrid
	corner(cell, 8)
	indexCells[def.id] = cell
end

-- Upgrades panel.
local upgradesPanel = Instance.new("Frame")
upgradesPanel.Name = "UpgradesPanel"
upgradesPanel.AnchorPoint = Vector2.new(0.5, 0.5)
upgradesPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
upgradesPanel.Size = UDim2.new(0, 560, 0, 420)
upgradesPanel.BackgroundColor3 = Config.PanelColor
upgradesPanel.BorderSizePixel = 0
upgradesPanel.Visible = false
upgradesPanel.Parent = screen
corner(upgradesPanel, 16)

local upgradesTitle = Instance.new("TextLabel")
upgradesTitle.Size = UDim2.new(1, -70, 0, 52)
upgradesTitle.Position = UDim2.new(0, 20, 0, 8)
upgradesTitle.BackgroundTransparency = 1
upgradesTitle.Text = "UPGRADES"
upgradesTitle.Font = Enum.Font.FredokaOne
upgradesTitle.TextScaled = true
upgradesTitle.TextXAlignment = Enum.TextXAlignment.Left
upgradesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradesTitle.Parent = upgradesPanel

local upgradesClose = Instance.new("TextButton")
upgradesClose.AnchorPoint = Vector2.new(1, 0)
upgradesClose.Position = UDim2.new(1, -12, 0, 10)
upgradesClose.Size = UDim2.new(0, 44, 0, 44)
upgradesClose.BackgroundColor3 = Config.CoralColor
upgradesClose.Text = "X"
upgradesClose.Font = Enum.Font.FredokaOne
upgradesClose.TextScaled = true
upgradesClose.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradesClose.Parent = upgradesPanel
corner(upgradesClose, 10)

local upgradeRows: { [string]: TextButton } = {}
do
	local y = 70
	for _, id in Config.UpgradeOrder do
		local up = Config.Upgrades[id]
		local row = Instance.new("TextButton")
		row.Name = id
		row.Position = UDim2.new(0, 20, 0, y)
		row.Size = UDim2.new(1, -40, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(24, 58, 74)
		row.BorderSizePixel = 0
		row.Text = up.label .. "  Lv 0  —  " .. up.blurb
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.Parent = upgradesPanel
		corner(row, 10)
		upgradeRows[id] = row
		y += 82
	end
end

-- State ----------------------------------------------------------------------

local currentBubbles = 0
local currentUpgrades: { [string]: number } = {}
local discovered: { [string]: boolean } = {}

local function upgradePrice(id: string, level: number): number
	local up = Config.Upgrades[id]
	return math.floor(up.basePrice * (up.growth ^ level))
end

local function refreshPanels(state: any)
	for id, row in upgradeRows do
		local level = (state.upgrades :: { [string]: number })[id] or 0
		local up = Config.Upgrades[id]
		if level >= up.maxLevel then
			row.Text = up.label .. "  MAX  —  " .. up.blurb
		else
			row.Text = up.label .. "  Lv " .. tostring(level) .. "  —  $" .. Format.withCommas(upgradePrice(id, level)) .. "  •  " .. up.blurb
		end
	end
	local found = state.indexCount :: number
	local bonus = ""
	if found >= 42 then
		bonus = "  (+42% money!)"
	end
	indexTitle.Text = "INDEX " .. tostring(found) .. "/42" .. bonus
	indexButton.Text = "INDEX " .. tostring(found) .. "/42"
end

local function refreshIndexCells()
	for _, def in Characters.List do
		local cell = indexCells[def.id]
		if cell then
			if discovered[def.id] then
				cell.Text = def.name .. "\n" .. string.upper(def.tier) .. "\n+$" .. tostring(def.earn) .. "/s"
				cell.TextColor3 = Color3.fromRGB(255, 255, 255)
				cell.BackgroundColor3 = Config.Tiers[def.tier].color
			else
				cell.Text = def.name .. "\n???\n+$" .. tostring(def.earn) .. "/s"
				cell.TextColor3 = Color3.fromRGB(140, 160, 170)
				cell.BackgroundColor3 = Color3.fromRGB(24, 58, 74)
			end
		end
	end
end

StateUpdate.OnClientEvent:Connect(function(state: any)
	local bubbles = state.bubbles :: number
	local rate = state.rate :: number
	local mult = state.mult :: number
	Juice.countUp(moneyLabel, currentBubbles, bubbles)
	currentBubbles = bubbles
	rateLabel.Text = Format.rate(rate)
	multPill.Text = "x" .. string.format("%.2f", mult):gsub("%.?0+$", "") .. " MONEY"
	currentUpgrades = state.upgrades
	discovered = state.discovered
	local feverLeft = state.feverLeft :: number
	if feverLeft > 0 then
		feverLabel.Visible = true
		feverLabel.Text = "DISCO FEVER x2 — " .. Format.clock(feverLeft) .. " left!"
	else
		feverLabel.Visible = false
	end
	refreshPanels(state)
end)

JuiceEvent.OnClientEvent:Connect(function(kind: string, a: any, b: any)
	Juice.handle(kind, a, b)
end)

-- Buttons ----------------------------------------------------------------------

local function toggle(frame: Frame)
	frame.Visible = not frame.Visible
	if frame.Visible then
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = frame.Size }):Play()
	end
end

upgradesButton.MouseButton1Click:Connect(function()
	Juice.press(upgradesButton)
	toggle(upgradesPanel)
end)
indexButton.MouseButton1Click:Connect(function()
	Juice.press(indexButton)
	refreshIndexCells()
	toggle(indexPanel)
end)
indexClose.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)
upgradesClose.MouseButton1Click:Connect(function()
	upgradesPanel.Visible = false
end)
for id, row in upgradeRows do
	row.MouseButton1Click:Connect(function()
		Juice.press(row)
		RequestBuyUpgrade:FireServer(id)
	end)
end
darkButton.MouseButton1Click:Connect(function()
	Juice.press(darkButton)
	RequestLock:FireServer()
end)
beatButton.MouseButton1Click:Connect(function()
	Juice.press(beatButton)
	Juice.eventBanner("DROP THE BEAT!", "The floor is yours — dance!")
end)

-- The index grid reads the discovered set from StateUpdate and lights a
-- cell up the moment its critter is deposited; refreshIndexCells runs
-- whenever the player opens the panel.
