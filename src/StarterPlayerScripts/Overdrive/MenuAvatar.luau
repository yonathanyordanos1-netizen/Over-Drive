--[[
	MenuAvatar
	The third-person figure standing in the middle of the dashboard.

	It is the Overdrive operator from CharacterSetup -- the same body the player
	will play as -- not their own Roblox avatar. The lobby is where a player sees
	what they look like in the match, so it has to show the match body.

	Built entirely on the client and parented into the client's Workspace.
	Nothing replicates: each player sees only their own figure, the server does
	no work, and no other client is sent a model it will never look at.

	The rig is anchored at the root so it holds its mark while its joints still
	animate, and every part is made non-collidable and non-queryable so a figure
	parked 800 studs above the map can never interfere with the match.

	If the operator cannot be built for any reason, a plain mannequin is built
	instead. A menu with a hole where the character should be is worse than a
	menu with a stand-in.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Overdrive")
local Config = require(Shared.Config)
local CharacterSetup = require(Shared.CharacterSetup)
local MenuCamera = require(script.Parent.MenuCamera)

local MenuAvatar = {}

local MODEL_NAME = "OverdriveMenuAvatar"

-- Classic idle animations, tried in order. The first that actually loads wins;
-- a stiff default pose is the fallback rather than an error.
local IDLE_ANIMATIONS = {
	"rbxassetid://507766666",
	"rbxassetid://507766951",
	"rbxassetid://507766388",
	"rbxassetid://180435571",
}

local model: Model? = nil
local track: AnimationTrack? = nil
local building = false

-- ===========================================================================
-- Fallback mannequin
-- ===========================================================================

local function block(parent: Instance, name: string, size: Vector3, offset: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Parent = parent
	return part
end

--[[
	A deliberately simple stand-in figure. It is posed slightly -- one foot
	forward, arms a little out from the body -- because a perfectly symmetrical
	block figure reads as broken geometry rather than as a character.
]]
local function buildMannequin(): Model
	local rig = Instance.new("Model")
	rig.Name = MODEL_NAME

	local shell = Color3.fromRGB(54, 58, 68)
	local trim = Config.Theme.Accent

	local root = block(rig, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), shell)
	root.Transparency = 1
	rig.PrimaryPart = root

	block(rig, "Torso", Vector3.new(2, 2.4, 1), Vector3.new(0, 3.1, 0), shell)
	block(rig, "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.8, 0), shell)
	block(rig, "Chestplate", Vector3.new(2.1, 0.9, 1.1), Vector3.new(0, 3.5, 0), trim)

	local leftArm = block(rig, "LeftArm", Vector3.new(0.8, 2.2, 0.8), Vector3.new(-1.5, 3, 0), shell)
	leftArm.CFrame = CFrame.new(-1.5, 3, 0) * CFrame.Angles(0, 0, math.rad(6))
	local rightArm = block(rig, "RightArm", Vector3.new(0.8, 2.2, 0.8), Vector3.new(1.5, 3, 0), shell)
	rightArm.CFrame = CFrame.new(1.5, 3, 0) * CFrame.Angles(0, 0, math.rad(-6))

	block(rig, "LeftLeg", Vector3.new(0.9, 2, 0.9), Vector3.new(-0.55, 1, 0.25), shell)
	block(rig, "RightLeg", Vector3.new(0.9, 2, 0.9), Vector3.new(0.55, 1, -0.3), shell)

	return rig
end

-- ===========================================================================
-- Placement
-- ===========================================================================

local function prepare(rig: Model)
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			-- Avatar models can arrive carrying scripts; the menu does not run them.
			descendant:Destroy()
		end
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Stop the rig trying to behave like a live character: no state machine,
		-- no falling, no name tag floating over the menu.
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayDistance = 0
		humanoid.NameDisplayDistance = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.EvaluateStateMachine = false
	end

	local root = rig:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		-- Anchoring only the root holds the figure on its mark while the joints
		-- are still free to animate.
		root.Anchored = true
	end
end

local function placeOnStand(rig: Model)
	local stand = MenuCamera.StandCFrame()

	-- PivotTo puts the model's centre at the target, so lift it by half its
	-- height to stand the figure on the mark rather than sink it into it.
	local _, size = rig:GetBoundingBox()
	rig:PivotTo(stand * CFrame.new(0, size.Y / 2, 0))
end

local function playIdle(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
		or Instance.new("Animator")
	animator.Parent = humanoid

	for _, assetId in IDLE_ANIMATIONS do
		local animation = Instance.new("Animation")
		animation.AnimationId = assetId

		local ok, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		if ok and loaded then
			local played = pcall(function()
				loaded.Looped = true
				loaded:Play(0.2)
			end)
			if played then
				return loaded, assetId
			end
		end
		animation:Destroy()
	end

	return nil
end

-- ===========================================================================
-- Public
-- ===========================================================================

--[[
	Builds the figure and stands it on the mark.
	Returns a short report so the caller can log which path was taken.
]]
function MenuAvatar.Build(player: Player)
	if building or model then
		return { alreadyBuilt = true }
	end
	building = true

	local report = { usedFallback = false }

	local ok, built = pcall(function()
		return CharacterSetup.BuildPreview(CharacterSetup.VariantFor(player))
	end)

	if not ok or not built then
		report.usedFallback = true
		report.reason = tostring(built)
		built = buildMannequin()
	end

	built.Name = MODEL_NAME
	prepare(built)
	built.Parent = Workspace
	placeOnStand(built)

	local loadedTrack, usedId = playIdle(built)
	track = loadedTrack
	report.idleAnimation = usedId or "none (static pose)"
	report.parts = #built:GetDescendants()

	model = built
	building = false
	return report
end

-- Re-seats the figure if the stage streamed in after the figure was built.
function MenuAvatar.Reseat()
	if model then
		placeOnStand(model)
	end
end

function MenuAvatar.SetVisible(visible: boolean)
	if not model then
		return
	end
	model.Parent = visible and Workspace or nil
end

function MenuAvatar.Destroy()
	if track then
		pcall(function()
			track:Stop()
		end)
		track = nil
	end
	if model then
		model:Destroy()
		model = nil
	end
end

function MenuAvatar.Get(): Model?
	return model
end

return MenuAvatar
