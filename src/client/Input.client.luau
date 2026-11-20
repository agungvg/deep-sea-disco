--!strict
-- Deep Sea Disco: player input. Collect, deposit and sell all run through
-- ProximityPrompts (E) on the critters and the deposit pad — the server
-- validates every trigger — so this script only owns the keys the prompts
-- do not: U opens Upgrades, I opens the Index, and the jump keeps a small
-- coyote-time grace window so the floor never eats a hop (P-05).
-- Keys are bound with ContextActionService, because the default camera
-- scripts swallow the arrow keys before InputBegan ever sees them.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Feel = require(Shared.Feel)

local player = Players.LocalPlayer

-- The HUD owns the panels; this script only asks for them by name.
local function hudPanel(name: string): Frame?
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("DeepSeaDiscoHud")
	if gui == nil then
		return nil
	end
	return gui:FindFirstChild(name) :: Frame?
end

local function togglePanel(name: string)
	local panel = hudPanel(name)
	if panel then
		panel.Visible = not panel.Visible
	end
end

ContextActionService:BindAction("DeepSeaDiscoUpgrades", function(_action: string, state: Enum.UserInputState, _input: InputObject)
	if state == Enum.UserInputState.Begin then
		togglePanel("UpgradesPanel")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.U)

ContextActionService:BindAction("DeepSeaDiscoIndex", function(_action: string, state: Enum.UserInputState, _input: InputObject)
	if state == Enum.UserInputState.Begin then
		togglePanel("IndexPanel")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.I)

-- Coyote time: a jump pressed just after leaving the floor still fires.
local lastGrounded = 0
local humanoid: Humanoid? = nil

local function watchCharacter(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	(humanoid :: Humanoid).StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.Landed then
			lastGrounded = os.clock()
		end
	end)
end

if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

UserInputService.JumpRequest:Connect(function()
	local h = humanoid
	if h == nil then
		return
	end
	if h.FloorMaterial == Enum.Material.Air and os.clock() - lastGrounded <= Feel.CoyoteTime then
		h:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
