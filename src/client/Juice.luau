--!strict
-- Deep Sea Disco: the client Juice module. One ModuleScript owns every
-- feedback channel — camera shake, floating income labels, event banners,
-- pickup pop and burst, count-up numbers, pitch-varied stings — all driven
-- by the one frozen FEEL table in ReplicatedStorage.Shared.Feel.
-- The server fires ReplicatedStorage/Remotes/Juice; this module plays it.
-- Juice never changes the rules: it only shows what the server decided.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Feel = require(Shared.Feel)
local Config = require(Shared.Config)
local Format = require(Shared.Format)

local Juice = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Settings: respect the platform reduce-motion flag.
local function shakeScale(): number
	local ok, reduced = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	if ok and reduced then
		return 0
	end
	return 1
end

-- Trauma camera shake. Bound after the camera updates; decays every frame.
local trauma = 0
local shakeTime = 0
local camera = workspace.CurrentCamera

local function addShake(amount: number)
	trauma = math.min(trauma + amount, 1)
end

RunService:BindToRenderStep("DeepSeaDiscoShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	if trauma <= 0 then
		return
	end
	if camera == nil then
		camera = workspace.CurrentCamera
		return
	end
	shakeTime += dt * 20
	local s = trauma * trauma * shakeScale()
	local maxAngle = math.rad(Feel.ShakeMaxAngleDeg)
	camera.CFrame *= CFrame.Angles(
		maxAngle * s * math.noise(shakeTime, 0),
		maxAngle * s * math.noise(0, shakeTime),
		maxAngle * s * math.noise(shakeTime, shakeTime)
	)
	trauma = math.max(trauma - Feel.ShakeDecay * dt, 0)
end)

-- Sounds: Roblox's built-in library, pitch-varied so repeats never drone.
local function sting(pitch: number)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.PlaybackSpeed = pitch
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	task.delay(1, function()
		sound:Destroy()
	end)
end

local function click()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/button.wav"
	sound.Volume = 0.4
	sound.PlaybackSpeed = 0.92 + math.random() * 0.16
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	task.delay(1, function()
		sound:Destroy()
	end)
end

-- UI pop: a UIScale tween that leaves Size and layout alone.
local function pop(gui: GuiObject, scale: number, seconds: number)
	local s = gui:FindFirstChildOfClass("UIScale")
	if s == nil then
		s = Instance.new("UIScale")
		s.Parent = gui
	end
	(s :: UIScale).Scale = scale
	TweenService:Create(
		s :: UIScale,
		TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

-- Floating income label: rises off a pedestal and fades. Pooled by count:
-- the caller never spawns more than one per tick per source.
local labelPool: { BillboardGui } = {}

local function floatLabel(worldPosition: Vector3, text: string, color: Color3)
	if #labelPool >= Feel.LabelPoolSize then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = nil
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = CFrame.new(worldPosition)
	anchor.Parent = workspace
	billboard.Adornee = anchor
	billboard.Parent = playerGui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.15
	label.Parent = billboard
	table.insert(labelPool, billboard)
	TweenService:Create(
		anchor,
		TweenInfo.new(Feel.LabelRiseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(worldPosition + Vector3.new(0, Feel.LabelRiseHeight, 0)) }
	):Play()
	task.delay(Feel.LabelRiseTime - 0.4, function()
		TweenService:Create(
			label,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end)
	task.delay(Feel.LabelRiseTime + 0.1, function()
		local i = table.find(labelPool, billboard)
		if i then
			table.remove(labelPool, i)
		end
		billboard:Destroy()
		anchor:Destroy()
	end)
end

-- Particle burst at a world position, pooled emitter style: one emitter,
-- reused by Emit, never created per event.
local burstPart: Part? = nil
local burstEmitter: ParticleEmitter? = nil

local function burst(worldPosition: Vector3, big: boolean)
	if burstPart == nil then
		local p = Instance.new("Part")
		p.Name = "JuiceBurst"
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 1
		p.Size = Vector3.new(0.1, 0.1, 0.1)
		p.Parent = workspace
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
		emitter.Color = ColorSequence.new(Config.LimeColor)
		emitter.Size = NumberSequence.new(0.6)
		emitter.Lifetime = NumberRange.new(Feel.ParticleLife)
		emitter.Rate = 0
		emitter.Speed = NumberRange.new(6, 12)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = p
		burstPart = p
		burstEmitter = emitter
	end
	(burstPart :: Part).CFrame = CFrame.new(worldPosition)
	if burstEmitter then
		burstEmitter:Emit(if big then Feel.ParticleBurstBig else Feel.ParticleBurst)
	end
end

-- Event banner: full-width, slides in, pops, dismisses itself. One at a
-- time — a new event replaces the one showing, never stacks.
local banner: Frame? = nil
local bannerTitle: TextLabel? = nil
local bannerSubtitle: TextLabel? = nil

local function buildBanner(): Frame
	local screen = Instance.new("ScreenGui")
	screen.Name = "DeepSeaDiscoBanner"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui
	local frame = Instance.new("Frame")
	frame.Name = "Banner"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)
	frame.Size = UDim2.new(0.78, 0, 0.075, 0)
	frame.BackgroundColor3 = Config.CoralColor
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = ""
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Parent = frame
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.new(0, 0, 0.55, 0)
	subtitle.Size = UDim2.new(1, 0, 0.45, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = ""
	subtitle.Font = Enum.Font.FredokaOne
	subtitle.TextScaled = true
	subtitle.TextColor3 = Color3.fromRGB(255, 240, 200)
	subtitle.Parent = frame
	banner = frame
	bannerTitle = title
	bannerSubtitle = subtitle
	return frame
end

local bannerToken = 0

function Juice.eventBanner(title: string, subtitle: string)
	local frame = banner or buildBanner()
	bannerToken += 1
	local token = bannerToken
	if bannerTitle then
		bannerTitle.Text = title
	end
	if bannerSubtitle then
		bannerSubtitle.Text = subtitle
	end
	frame.Visible = true
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)
	TweenService:Create(
		frame,
		TweenInfo.new(Feel.BannerInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.075, 0) }
	):Play()
	pop(frame, 1.06, 0.25)
	addShake(Feel.ShakeAddEvent)
	sting(0.9 + math.random() * 0.2)
	task.delay(Feel.BannerHoldTime, function()
		if token ~= bannerToken then
			return
		end
		TweenService:Create(
			frame,
			TweenInfo.new(Feel.BannerOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, -0.15, 0) }
		):Play()
		task.delay(Feel.BannerOutTime, function()
			if token == bannerToken then
				frame.Visible = false
			end
		end)
	end)
end

-- Count-up numbers: a balance that tweens to its target reads as earned.
function Juice.countUp(label: TextLabel, from: number, to: number)
	local v = Instance.new("NumberValue")
	v.Value = from
	v.Changed:Connect(function(value: number)
		label.Text = "$" .. Format.withCommas(math.floor(value))
	end)
	TweenService:Create(
		v,
		TweenInfo.new(Feel.CountUpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = to }
	):Play()
	task.delay(Feel.CountUpTime + 0.1, function()
		v:Destroy()
	end)
end

function Juice.press(gui: GuiObject)
	pop(gui, 0.93, 0.15)
	click()
end

-- The one handler the server talks to.
function Juice.handle(kind: string, a: any, b: any)
	if kind == "pickup" then
		local position = a :: Vector3
		burst(position, false)
		addShake(Feel.ShakeAddPickup)
		sting(1 + math.random() * 0.1)
		floatLabel(position + Vector3.new(0, 1, 0), "CAUGHT!", Config.LimeColor)
	elseif kind == "deposit" then
		local earn = a :: number
		local name = b :: string
		burst(Vector3.new(0, 6, 10), true)
		addShake(Feel.ShakeAddPickup)
		sting(1.2)
		floatLabel(Vector3.new(0, 6, 10), name .. " is dancing! +$" .. tostring(earn) .. "/s", Config.LimeColor)
	elseif kind == "sell" then
		local price = a :: number
		floatLabel(Vector3.new(0, 6, 10), "SOLD +$" .. Format.withCommas(price), Config.GoldColor)
		sting(1.1)
	elseif kind == "buy" then
		local _price = a
		local label = b :: string
		sting(1.25)
		floatLabel(Vector3.new(0, 6, 10), label .. " upgraded!", Config.TealColor)
	elseif kind == "income" then
		local position = a :: Vector3
		local gain = b :: number
		floatLabel(position, "+$" .. Format.withCommas(gain), Config.LimeColor)
	elseif kind == "event" then
		Juice.eventBanner(a :: string, b :: string)
	elseif kind == "hurt" then
		addShake(Feel.ShakeAddHurt)
		sting(0.7)
	elseif kind == "denied" then
		local message = a :: string
		floatLabel(Vector3.new(0, 6, 10), message, Config.CoralColor)
	elseif kind == "locked" then
		Juice.eventBanner("GO DARK!", "Your base is locked for " .. tostring(a) .. "s — the Nabber can't touch it.")
	end
end

return Juice
