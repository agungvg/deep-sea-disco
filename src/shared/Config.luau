--!strict
-- Deep Sea Disco: one shared tuning table for the whole game.
-- Palette: deep teal/navy water, coral orange, warm sand, lime accents.
-- Nothing here is a secret; the server owns every number that pays out.

local Config = {}

-- Water and light.
Config.WaterColor = Color3.fromRGB(6, 42, 51)
Config.DeepColor = Color3.fromRGB(11, 30, 45)
Config.SandColor = Color3.fromRGB(232, 201, 138)
Config.SandDark = Color3.fromRGB(198, 164, 96)
Config.CoralColor = Color3.fromRGB(255, 122, 89)
Config.LimeColor = Color3.fromRGB(184, 230, 46)
Config.TealColor = Color3.fromRGB(46, 196, 182)
Config.GoldColor = Color3.fromRGB(255, 201, 60)
Config.PanelColor = Color3.fromRGB(13, 38, 52)
Config.PanelEdge = Color3.fromRGB(46, 196, 182)

-- Rarity tiers, in ladder order. Colour is an accent only, never a body colour.
export type TierName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Abyssal"

Config.Tiers = {
	Common = { order = 1, color = Color3.fromRGB(232, 217, 160), weight = 55 },
	Rare = { order = 2, color = Color3.fromRGB(46, 196, 182), weight = 25 },
	Epic = { order = 3, color = Color3.fromRGB(255, 122, 89), weight = 12 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 201, 60), weight = 5 },
	Mythic = { order = 5, color = Color3.fromRGB(179, 136, 235), weight = 2 },
	Abyssal = { order = 6, color = Color3.fromRGB(184, 230, 46), weight = 1 },
}

Config.TierOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Abyssal" }

-- Spawning in the Open Water.
Config.SpawnInterval = 4
Config.MaxWild = 12
Config.SpawnArea = { minX = -70, maxX = 70, minZ = -55, maxZ = -6 }
Config.CarryRange = 9
Config.DepositRange = 10

-- Economy.
Config.StartBubbles = 0
Config.SellFraction = 0.8
Config.IndexFullBonus = 0.42 -- 42/42 discovered: +42% Bubbles.
Config.IncomeTick = 1
Config.SaveInterval = 60
Config.DataStoreName = "DeepSeaDiscoSaveV1"
Config.DataVersion = 1

-- Upgrades. Each row: base price, price growth per level, max level, effect per level.
Config.Upgrades = {
	WalkSpeed = {
		label = "Flipper Speed",
		blurb = "+2 walk speed per level",
		basePrice = 150,
		growth = 2.2,
		maxLevel = 5,
	},
	CarryCap = {
		label = "Bubble Net",
		blurb = "+1 critter carried per level",
		basePrice = 400,
		growth = 2.6,
		maxLevel = 2,
	},
	MoneyMult = {
		label = "Disco Amplifier",
		blurb = "+25% Bubbles per level",
		basePrice = 1000,
		growth = 3.0,
		maxLevel = 8,
	},
	BaseSlots = {
		label = "More Pedestals",
		blurb = "+2 dance pedestals per level",
		basePrice = 750,
		growth = 2.4,
		maxLevel = 3,
	},
}

Config.BaseWalkSpeed = 16
Config.BaseCarryCap = 1
Config.BasePedestals = 4
Config.UpgradeOrder = { "WalkSpeed", "CarryCap", "MoneyMult", "BaseSlots" }

-- Live events.
Config.Events = {
	DiscoFever = { everySeconds = 240, duration = 45, multiplier = 2 },
	NetNabber = { everySeconds = 180, escapeSeconds = 22 },
	SharkSweep = { everySeconds = 300, crossSeconds = 9 },
}

-- Base lock ("Go Dark"): a locked base cannot be robbed by the Net Nabber.
Config.LockDuration = 60
Config.LockCooldown = 120

-- How many bases ring the dance floor, and where they sit.
Config.BaseCount = 6
Config.BaseRadius = 86

return Config
