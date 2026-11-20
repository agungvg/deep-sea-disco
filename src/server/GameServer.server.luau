--!strict
-- Deep Sea Disco: the server. It owns everything valuable — Bubbles,
-- inventory, spawns, events, saves — and the client only asks.
-- Remote contract (ReplicatedStorage/Remotes):
--   RequestCollect (player, uid)      -> carry a wild critter, if in range
--   RequestDeposit (player)           -> put the carried critter on a pedestal
--   RequestSell (player, uid)         -> sell an owned critter for 80% of cost
--   RequestBuyUpgrade (player, id)    -> buy one upgrade level
--   RequestLock (player)              -> Go Dark: lock your base for 60s
--   StateUpdate (server -> player)    -> bubbles, rate, multiplier, index, upgrades
--   Juice (server -> player(s))       -> kind + args for the client Juice module
-- ProximityPrompts on critters and the deposit pad call the same handlers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Characters = require(Shared.Characters)
local Config = require(Shared.Config)
local Format = require(Shared.Format)

local ServerFolder = script.Parent
local World = require(ServerFolder.World)
local Bases = require(ServerFolder.Bases)
local CharacterFactory = require(ServerFolder.CharacterFactory)
local ThiefAI = require(ServerFolder.ThiefAI)
local Events = require(ServerFolder.Events)

-- Remotes, created here so the client never has to guess.
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage
local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = Remotes
	return r
end
local RequestCollect = remote("RequestCollect")
local RequestDeposit = remote("RequestDeposit")
local RequestSell = remote("RequestSell")
local RequestBuyUpgrade = remote("RequestBuyUpgrade")
local RequestLock = remote("RequestLock")
local StateUpdate = remote("StateUpdate")
local JuiceEvent = remote("Juice")

export type OwnedCritter = {
	uid: string,
	defId: string,
	pedestal: number,
}

export type PlayerData = {
	bubbles: number,
	owned: { OwnedCritter },
	discovered: { [string]: boolean },
	upgrades: { [string]: number },
	lockedUntil: number,
	lockReadyAt: number,
}

local dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
local playerData: { [Player]: PlayerData } = {}
local carrying: { [Player]: { string } } = {} -- player -> wild uids carried
local lastAction: { [Player]: number } = {}

type WildCritter = {
	uid: string,
	def: Characters.CritterDef,
	model: Model,
	home: CFrame,
	phase: number,
	carriedBy: Player?,
}
local wild: { [string]: WildCritter } = {}
local wildCount = 0
local wildFolder = Instance.new("Folder")
wildFolder.Name = "WildCritters"
wildFolder.Parent = workspace

local rng = Random.new()
local uidCounter = 0

local function newUid(): string
	uidCounter += 1
	return "c" .. tostring(uidCounter) .. "-" .. HttpService:GenerateGUID(false)
end

local function defaultData(): PlayerData
	return {
		bubbles = Config.StartBubbles,
		owned = {},
		discovered = {},
		upgrades = { WalkSpeed = 0, CarryCap = 0, MoneyMult = 0, BaseSlots = 0 },
		lockedUntil = 0,
		lockReadyAt = 0,
	}
end

local function rateLimit(player: Player, seconds: number): boolean
	local now = os.clock()
	if lastAction[player] ~= nil and now - (lastAction[player] :: number) < seconds then
		return false
	end
	lastAction[player] = now
	return true
end

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function indexCount(data: PlayerData): number
	local n = 0
	for _ in data.discovered do
		n += 1
	end
	return n
end

local function indexFull(data: PlayerData): boolean
	return indexCount(data) >= 42
end

local function multiplierOf(data: PlayerData): number
	local mult = 1 + 0.25 * (data.upgrades.MoneyMult or 0)
	if Events.isFever() then
		mult *= Config.Events.DiscoFever.multiplier
	end
	if indexFull(data) then
		mult *= 1 + Config.IndexFullBonus
	end
	return mult
end

local function rateOf(data: PlayerData): number
	local base = 0
	for _, owned in data.owned do
		local def = Characters.ById[owned.defId]
		if def then
			base += def.earn
		end
	end
	return math.floor(base * multiplierOf(data))
end

local function sendState(player: Player)
	local data = playerData[player]
	if data == nil then
		return
	end
	local base = Bases.of(player)
	local pedestalCount = 0
	if base ~= nil then
		pedestalCount = #base.pedestals
	end
	StateUpdate:FireClient(player, {
		bubbles = math.floor(data.bubbles),
		rate = rateOf(data),
		mult = multiplierOf(data),
		indexCount = indexCount(data),
		indexTotal = 42,
		upgrades = data.upgrades,
		ownedCount = #data.owned,
		pedestals = pedestalCount,
		lockedUntil = data.lockedUntil,
		feverLeft = Events.feverLeft(),
		discovered = data.discovered,
	})
end

local function juice(player: Player, kind: string, a: any, b: any)
	JuiceEvent:FireClient(player, kind, a, b)
end

local function juiceAll(kind: string, a: any, b: any)
	JuiceEvent:FireAllClients(kind, a, b)
end

local function announce(title: string, subtitle: string)
	juiceAll("event", title, subtitle)
end

-- Wild critters ------------------------------------------------------------

local function spawnWild(def: Characters.CritterDef?, position: Vector3?)
	local pick = def or Characters.roll(rng)
	local area = Config.SpawnArea
	local pos = position
		or Vector3.new(rng:NextNumber(area.minX, area.maxX), 0, rng:NextNumber(area.minZ, area.maxZ))
	local model = CharacterFactory.build(pick, pos, rng:NextNumber(0, math.pi * 2))
	model.Parent = wildFolder
	local uid = newUid()
	model.Name = uid
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Carry " .. pick.name
	prompt.ObjectText = pick.tier .. "  +$" .. tostring(pick.earn) .. "/s"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player: Player)
		collectCritter(player, uid)
	end)
	wild[uid] = { uid = uid, def = pick, model = model, home = model:GetPivot(), phase = rng:NextNumber(0, math.pi * 2), carriedBy = nil }
	wildCount += 1
end

local function destroyWild(uid: string)
	local entry = wild[uid]
	if entry == nil then
		return
	end
	if entry.model.Parent ~= nil then
		entry.model:Destroy()
	end
	wild[uid] = nil
	-- Only count it out of the wild cap if it was actually wild;
	-- a carried critter was already counted out when it was picked up.
	if entry.carriedBy == nil then
		wildCount -= 1
	end
end

-- Collect / deposit / sell -------------------------------------------------

function collectCritter(player: Player, uid: string)
	local data = playerData[player]
	local entry = wild[uid]
	if data == nil or entry == nil then
		return
	end
	if not rateLimit(player, 0.5) then
		return
	end
	local root = playerRoot(player)
	if root == nil then
		return
	end
	if (root.Position - entry.model:GetPivot().Position).Magnitude > Config.CarryRange + 2 then
		return
	end
	local carried = 0
	local myList = carrying[player]
	if myList ~= nil then
		carried = #myList
	end
	local cap = Config.BaseCarryCap + (data.upgrades.CarryCap or 0)
	if carried >= cap then
		juice(player, "denied", "Net full! Deposit at your base first.")
		return
	end
	entry.carriedBy = player
	if myList == nil then
		carrying[player] = { uid }
	else
		table.insert(myList, uid)
	end
	-- Counted out of the wild cap so the spawner refills the Open Water,
	-- but the entry stays in the table so deposit can find its def.
	wildCount -= 1
	juice(player, "pickup", entry.model:GetPivot().Position, entry.def.earn)
end

local function depositCritter(player: Player)
	local data = playerData[player]
	local myList = carrying[player]
	if data == nil or myList == nil or #myList == 0 then
		return
	end
	if not rateLimit(player, 0.5) then
		return
	end
	local base = Bases.of(player)
	if base == nil then
		return
	end
	local root = playerRoot(player)
	if root == nil then
		return
	end
	if (root.Position - base.center).Magnitude > 16 then
		juice(player, "denied", "Get back to your own base to deposit!")
		return
	end
	local ped = Bases.freePedestal(base)
	if ped == nil then
		juice(player, "denied", "No free pedestal! Buy More Pedestals.")
		return
	end
	local uid = myList[#myList]
	table.remove(myList, #myList)
	local entry = wild[uid]
	-- The carried critter's def lives in the wild table until deposit.
	if entry == nil or entry.carriedBy ~= player then
		return
	end
	local def = entry.def
	local pedIndex = table.find(base.pedestals, ped) or 1
	if entry.model.Parent ~= nil then
		entry.model:Destroy()
	end
	wild[uid] = nil
	-- No wildCount change: it was already counted out when picked up.

	local ownedUid = newUid()
	local ownedModel = CharacterFactory.build(def, ped.part.Position + Vector3.new(0, 1.6, 0), 0)
	ownedModel.Name = ownedUid
	ownedModel.Parent = base.folder
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.ActionText = "Sell for $" .. Format.withCommas(math.floor(def.cost * Config.SellFraction))
	sellPrompt.ObjectText = def.name
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
	sellPrompt.HoldDuration = 0
	sellPrompt.MaxActivationDistance = 6
	sellPrompt.Parent = ownedModel.PrimaryPart
	sellPrompt.Triggered:Connect(function(seller: Player)
		sellCritter(seller, ownedUid)
	end)
	table.insert(data.owned, { uid = ownedUid, defId = def.id, pedestal = pedIndex })
	data.discovered[def.id] = true
	ped.occupiedBy = ownedUid
	Bases.setPedestalTag(ped, math.floor(def.earn * multiplierOf(data)))
	juice(player, "deposit", def.earn, def.name)
	sendState(player)
end

function sellCritter(player: Player, uid: string)
	local data = playerData[player]
	if data == nil then
		return
	end
	if not rateLimit(player, 0.5) then
		return
	end
	local found: number? = nil
	local foundDef: Characters.CritterDef? = nil
	for i, owned in data.owned do
		if owned.uid == uid then
			found = i
			foundDef = Characters.ById[owned.defId]
			break
		end
	end
	if found == nil or foundDef == nil then
		return
	end
	local base = Bases.of(player)
	if base == nil then
		return
	end
	local root = playerRoot(player)
	if root == nil then
		return
	end
	if (root.Position - base.center).Magnitude > 18 then
		juice(player, "denied", "You can only sell at your own base!")
		return
	end
	local def = foundDef :: Characters.CritterDef
	local price = math.floor(def.cost * Config.SellFraction)
	table.remove(data.owned, found :: number)
	data.bubbles += price
	for _, candidate in base.pedestals do
		if candidate.occupiedBy == uid then
			candidate.occupiedBy = nil
			Bases.clearPedestalTag(candidate)
			break
		end
	end
	local model = base.folder:FindFirstChild(uid)
	if model then
		model:Destroy()
	end
	juice(player, "sell", price, def.name)
	sendState(player)
end

-- Upgrades and locking ------------------------------------------------------

local function upgradePrice(id: string, level: number): number
	local up = Config.Upgrades[id]
	return math.floor(up.basePrice * (up.growth ^ level))
end

local function buyUpgrade(player: Player, id: string)
	local data = playerData[player]
	local up = Config.Upgrades[id]
	if data == nil or up == nil then
		return
	end
	if not rateLimit(player, 0.5) then
		return
	end
	local level = data.upgrades[id] or 0
	if level >= up.maxLevel then
		juice(player, "denied", up.label .. " is maxed out!")
		return
	end
	local price = upgradePrice(id, level)
	if data.bubbles < price then
		juice(player, "denied", "Not enough Bubbles! Need $" .. Format.withCommas(price) .. ".")
		return
	end
	data.bubbles -= price
	data.upgrades[id] = level + 1
	if id == "WalkSpeed" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.BaseWalkSpeed + 2 * (level + 1)
		end
	elseif id == "BaseSlots" then
		local base = Bases.of(player)
		if base then
			Bases.addPedestals(base, 2)
		end
	end
	juice(player, "buy", price, up.label)
	sendState(player)
end

local function lockBase(player: Player)
	local data = playerData[player]
	if data == nil then
		return
	end
	local now = os.clock()
	if now < data.lockReadyAt then
		juice(player, "denied", "Go Dark is recharging!")
		return
	end
	data.lockedUntil = now + Config.LockDuration
	data.lockReadyAt = now + Config.LockCooldown
	juice(player, "locked", Config.LockDuration, nil)
	sendState(player)
end

local function baseLocked(player: Player): boolean
	local data = playerData[player]
	return data ~= nil and os.clock() < data.lockedUntil
end

-- Saves ---------------------------------------------------------------------

local function savePlayer(player: Player)
	local data = playerData[player]
	if data == nil then
		return
	end
	local snapshot = {
		version = Config.DataVersion,
		bubbles = math.floor(data.bubbles),
		owned = data.owned,
		discovered = data.discovered,
		upgrades = data.upgrades,
	}
	local ok, err = pcall(function()
		dataStore:SetAsync("player_" .. tostring(player.UserId), snapshot)
	end)
	if not ok then
		warn("Deep Sea Disco: save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function loadPlayer(player: Player): PlayerData
	local data = defaultData()
	local ok, saved = pcall(function()
		return dataStore:GetAsync("player_" .. tostring(player.UserId))
	end)
	if ok and type(saved) == "table" and saved.version == Config.DataVersion then
		data.bubbles = saved.bubbles or 0
		data.owned = saved.owned or {}
		data.discovered = saved.discovered or {}
		data.upgrades = saved.upgrades or data.upgrades
	end
	return data
end

local function rebuildOwned(player: Player)
	local data = playerData[player]
	local base = Bases.of(player)
	if data == nil or base == nil then
		return
	end
	for _, owned in data.owned do
		local def = Characters.ById[owned.defId]
		if def then
			local ped = base.pedestals[owned.pedestal]
			if ped then
				local model = CharacterFactory.build(def, ped.part.Position + Vector3.new(0, 1.6, 0), 0)
				model.Name = owned.uid
				model.Parent = base.folder
				local sellPrompt = Instance.new("ProximityPrompt")
				sellPrompt.ActionText = "Sell for $" .. Format.withCommas(math.floor(def.cost * Config.SellFraction))
				sellPrompt.ObjectText = def.name
				sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
				sellPrompt.HoldDuration = 0
				sellPrompt.MaxActivationDistance = 6
				sellPrompt.Parent = model.PrimaryPart
				sellPrompt.Triggered:Connect(function(seller: Player)
					sellCritter(seller, owned.uid)
				end)
				ped.occupiedBy = owned.uid
				Bases.setPedestalTag(ped, math.floor(def.earn * multiplierOf(data)))
			end
		end
	end
end

-- Player lifecycle -----------------------------------------------------------

local function onPlayerAdded(player: Player)
	local data = loadPlayer(player)
	playerData[player] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local bubblesValue = Instance.new("IntValue")
	bubblesValue.Name = "Bubbles"
	bubblesValue.Value = math.floor(data.bubbles)
	bubblesValue.Parent = leaderstats
	local indexValue = Instance.new("IntValue")
	indexValue.Name = "Index"
	indexValue.Value = indexCount(data)
	indexValue.Parent = leaderstats

	local base = Bases.claimFor(player)
	if base == nil then
		juice(player, "denied", "All disco bases are taken! Try another server.")
	end
	rebuildOwned(player)

	player.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.WalkSpeed = Config.BaseWalkSpeed + 2 * (data.upgrades.WalkSpeed or 0)
		task.delay(0.5, function()
			sendState(player)
		end)
	end)
	sendState(player)
end

local function onPlayerRemoving(player: Player)
	savePlayer(player)
	local myList = carrying[player]
	if myList ~= nil then
		for _, uid in myList do
			destroyWild(uid)
		end
		carrying[player] = nil
	end
	local base = Bases.of(player)
	if base then
		for _, owned in (playerData[player] or defaultData()).owned do
			local model = base.folder:FindFirstChild(owned.uid)
			if model then
				model:Destroy()
			end
		end
		for _, ped in base.pedestals do
			ped.occupiedBy = nil
			Bases.clearPedestalTag(ped)
		end
	end
	Bases.release(player)
	playerData[player] = nil
	lastAction[player] = nil
end

-- Income and world heartbeat -------------------------------------------------

local function incomeTick()
	for player, data in playerData do
		local gain = rateOf(data)
		if gain > 0 then
			data.bubbles += gain
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local bubblesValue = stats:FindFirstChild("Bubbles") :: IntValue?
				if bubblesValue then
					bubblesValue.Value = math.floor(data.bubbles)
				end
				local indexValue = stats:FindFirstChild("Index") :: IntValue?
				if indexValue then
					indexValue.Value = indexCount(data)
				end
			end
			-- A floating +N label rises off one of the player's pedestals.
			local base = Bases.of(player)
			if base and #data.owned > 0 then
				local owned = data.owned[math.random(1, #data.owned)]
				local ped = base.pedestals[owned.pedestal]
				if ped then
					juice(player, "income", ped.part.Position + Vector3.new(0, 2.5, 0), gain)
				end
			end
		end
		sendState(player)
	end
end

local function bobCritters()
	local t = os.clock()
	for _, entry in wild do
		if entry.carriedBy == nil then
			local model = entry.model
			if model.Parent ~= nil and model.PrimaryPart ~= nil then
				local bob = math.sin(t * 1.6 + entry.phase) * 0.35
				local sway = math.sin(t * 0.9 + entry.phase) * 0.12
				model:PivotTo(entry.home * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, 0))
			end
		end
	end
	-- Carried critters hover above their carrier's head, mid-hop.
	for player, myList in carrying do
		local root = playerRoot(player)
		if root then
			for i, uid in myList do
				local entry = wild[uid]
				if entry then
					local hop = math.abs(math.sin(t * 6 + i)) * 0.5
					entry.model:PivotTo(CFrame.new(root.Position + Vector3.new((i - 1) * 1.6 - 0.8, 3.6 + hop, 0)))
				end
			end
		end
	end
end

-- Events ---------------------------------------------------------------------

local function pickNabberVictim(): (Player?, ThiefAI.StolenCritter?)
	local candidates = {}
	for player, data in playerData do
		if #data.owned > 0 and not baseLocked(player) then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return nil, nil
	end
	local victim = candidates[math.random(1, #candidates)]
	local data = playerData[victim] :: PlayerData
	local stolen = data.owned[math.random(1, #data.owned)]
	-- Remove it from the base now; the thief physically carries the record.
	for i, owned in data.owned do
		if owned.uid == stolen.uid then
			table.remove(data.owned, i)
			break
		end
	end
	local base = Bases.of(victim)
	if base then
		local model = base.folder:FindFirstChild(stolen.uid)
		if model then
			model:Destroy()
		end
		for _, ped in base.pedestals do
			if ped.occupiedBy == stolen.uid then
				ped.occupiedBy = nil
				Bases.clearPedestalTag(ped)
				break
			end
		end
	end
	sendState(victim)
	return victim, { uid = stolen.uid, defId = stolen.defId }
end

local function returnStolen(victim: Player, stolen: ThiefAI.StolenCritter)
	local data = playerData[victim]
	if data == nil then
		return
	end
	local base = Bases.of(victim)
	local def = Characters.ById[stolen.defId]
	if base == nil or def == nil then
		return
	end
	local ped = Bases.freePedestal(base)
	if ped == nil then
		return
	end
	local pedIndex = table.find(base.pedestals, ped) or 1
	local model = CharacterFactory.build(def, ped.part.Position + Vector3.new(0, 1.6, 0), 0)
	model.Name = stolen.uid
	model.Parent = base.folder
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.ActionText = "Sell for $" .. Format.withCommas(math.floor(def.cost * Config.SellFraction))
	sellPrompt.ObjectText = def.name
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
	sellPrompt.HoldDuration = 0
	sellPrompt.MaxActivationDistance = 6
	sellPrompt.Parent = model.PrimaryPart
	sellPrompt.Triggered:Connect(function(seller: Player)
		sellCritter(seller, stolen.uid)
	end)
	table.insert(data.owned, { uid = stolen.uid, defId = stolen.defId, pedestal = pedIndex })
	ped.occupiedBy = stolen.uid
	Bases.setPedestalTag(ped, math.floor(def.earn * multiplierOf(data)))
	juice(victim, "deposit", def.earn, def.name)
	sendState(victim)
end

local function loseStolen(victim: Player, _stolen: ThiefAI.StolenCritter)
	-- Escaped into the trench: the critter is gone for good.
	sendState(victim)
end

local function sharkHit(player: Player)
	local myList = carrying[player]
	if myList ~= nil and #myList > 0 then
		-- Drop the carried critter back into the Open Water.
		local uid = myList[#myList]
		table.remove(myList, #myList)
		local entry = wild[uid]
		if entry then
			local root = playerRoot(player)
			local dropAt = root and (root.Position + Vector3.new(0, 0, 6)) or Vector3.new(0, 0, -30)
			entry.carriedBy = nil
			entry.home = CFrame.new(dropAt)
			entry.model:PivotTo(entry.home)
			wildCount += 1
		end
		juice(player, "hurt", nil, nil)
		juice(player, "denied", "The shark knocked your critter loose!")
	else
		juice(player, "hurt", nil, nil)
	end
	-- Knockback: shove the player toward their base.
	local root = playerRoot(player)
	if root then
		local base = Bases.of(player)
		local away = Vector3.new(0, 0, 10)
		if base then
			away = (base.center - root.Position).Unit * 10
			away = Vector3.new(away.X, 0, away.Z)
		end
		root.CFrame = root.CFrame + away + Vector3.new(0, 2, 0)
	end
end

-- Wiring ----------------------------------------------------------------------

RequestCollect.OnServerEvent:Connect(function(player: Player, uid: any)
	if typeof(uid) == "string" then
		collectCritter(player, uid)
	end
end)
RequestDeposit.OnServerEvent:Connect(function(player: Player)
	depositCritter(player)
end)
RequestSell.OnServerEvent:Connect(function(player: Player, uid: any)
	if typeof(uid) == "string" then
		sellCritter(player, uid)
	end
end)
RequestBuyUpgrade.OnServerEvent:Connect(function(player: Player, id: any)
	if typeof(id) == "string" then
		buyUpgrade(player, id)
	end
end)
RequestLock.OnServerEvent:Connect(function(player: Player)
	lockBase(player)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayer(player)
	end
end)

-- Boot ------------------------------------------------------------------------

local spots = World.build()
Bases.build(spots)

-- Seed the Open Water so the first player sees a full floor.
for _ = 1, 8 do
	spawnWild(nil, nil)
end

task.spawn(function()
	while true do
		task.wait(Config.SpawnInterval)
		if wildCount < Config.MaxWild then
			spawnWild(nil, nil)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.IncomeTick)
		incomeTick()
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		bobCritters()
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.SaveInterval)
		for _, player in Players:GetPlayers() do
			savePlayer(player)
		end
	end
end)

-- Event scheduler: fever first, then the nabber, then the shark, staggered.
task.spawn(function()
	task.wait(60)
	while true do
		Events.startFever(announce)
		task.wait(Config.Events.DiscoFever.everySeconds)
	end
end)
task.spawn(function()
	task.wait(120)
	while true do
		if not ThiefAI.isRunning() then
			task.spawn(ThiefAI.run, pickNabberVictim, returnStolen, loseStolen, announce)
		end
		task.wait(Config.Events.NetNabber.everySeconds)
	end
end)
task.spawn(function()
	task.wait(200)
	while true do
		Events.runSharkSweep(announce, sharkHit)
		task.wait(Config.Events.SharkSweep.everySeconds)
	end
end)
