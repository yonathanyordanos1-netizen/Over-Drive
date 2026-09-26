--[[
	CharacterSetup
	The Overdrive operator: one tall, human-proportioned R15 body that every
	player uses, whatever their own Roblox avatar looks like.

	This module is the single place the body is defined. The lobby builds its
	preview figure from it today; gameplay spawning will call Spawn() once the
	match mechanics exist. Swapping in a fully custom mesh later means
	changing this module only -- nothing else reads body sizes directly.

	Why a rescaled R15 rather than a custom rig:
	  * Standard part and attachment names are kept, so Roblox's default
	    animations, RightGripAttachment tool grips and any attachment-based
	    grapple keep working without being rewritten.
	  * BodyTypeScale and ProportionScale change the *ratios* -- longer legs
	    and torso, smaller head -- which is what moves the body from a
	    4.6-heads-tall toy to an 8-heads-tall human. Height alone would only
	    make a bigger toy.

	Uniformity is deliberate. Every player gets the same body and the same
	proportions, with no avatar accessories, hair or clothing templates, so
	hitboxes are identical for everyone and no avatar item can hide a limb or
	bulk out a silhouette.

	Measured result (built and measured in Studio):
	  height 7.66 studs (default 5.46), 8.0 heads tall (default 4.6),
	  shoulders 3.05 (default 3.95), hip height 3.57 (default 2.19)
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterSetup = {}

-- ===========================================================================
-- Body
-- ===========================================================================

CharacterSetup.Scales = {
	HeightScale = 1.35,
	WidthScale = 0.80,
	DepthScale = 0.85,
	HeadScale = 0.85,
	BodyTypeScale = 1.0, -- 0.5 gives a stockier 7.24-stud build
	ProportionScale = 1.0,
}

-- The R15 parts, and which region of the outfit each one wears.
local PART_REGIONS = {
	Head = "Head",
	UpperTorso = "Jacket",
	LowerTorso = "Trousers",
	LeftUpperArm = "Jacket",
	LeftLowerArm = "Jacket",
	RightUpperArm = "Jacket",
	RightLowerArm = "Jacket",
	LeftHand = "Gloves",
	RightHand = "Gloves",
	LeftUpperLeg = "Trousers",
	LeftLowerLeg = "Trousers",
	RightUpperLeg = "Trousers",
	RightLowerLeg = "Trousers",
	LeftFoot = "Boots",
	RightFoot = "Boots",
}

-- Damage regions, for the gun system to apply multipliers against.
local HIT_REGIONS = {
	Head = "Head",
	UpperTorso = "Torso",
	LowerTorso = "Torso",
}

-- ===========================================================================
-- Look
--
-- The head is a dark balaclava rather than skin with a face decal: it reads
-- as a tactical operator without any avatar item, and it hides how simple
-- the head shape is. Set ShowFace = true to go back to a face.
--
-- One shared material for the whole uniform, one for the hard kit. Variants
-- change colour only, so every team is the same object with different paint.
-- ===========================================================================

CharacterSetup.ShowFace = false

CharacterSetup.Materials = {
	Head = Enum.Material.Fabric,
	Jacket = Enum.Material.Fabric,
	Trousers = Enum.Material.Fabric,
	Gloves = Enum.Material.SmoothPlastic,
	Boots = Enum.Material.SmoothPlastic,
}

local KIT_BLACK = Color3.fromRGB(24, 24, 27)
local BALACLAVA = Color3.fromRGB(30, 30, 33)

CharacterSetup.Variants = {
	-- Brand colours: rust jacket over charcoal.
	Ember = {
		Label = "EMBER",
		Head = BALACLAVA,
		Jacket = Color3.fromRGB(122, 56, 30),
		Trousers = Color3.fromRGB(48, 46, 48),
		Gloves = KIT_BLACK,
		Boots = KIT_BLACK,
	},
	-- Cold slate blue-grey, the opposite team to Ember.
	Steel = {
		Label = "STEEL",
		Head = BALACLAVA,
		Jacket = Color3.fromRGB(64, 84, 108),
		Trousers = Color3.fromRGB(44, 50, 60),
		Gloves = KIT_BLACK,
		Boots = KIT_BLACK,
	},
	-- Neutral olive drab: free-for-all, and anyone without a team.
	Olive = {
		Label = "OLIVE",
		Head = BALACLAVA,
		Jacket = Color3.fromRGB(88, 94, 60),
		Trousers = Color3.fromRGB(64, 68, 48),
		Gloves = KIT_BLACK,
		Boots = KIT_BLACK,
	},
}

CharacterSetup.DefaultVariant = "Olive"

--[[
	Team -> variant, keyed by BrickColor name. There are no Teams yet; when the
	match system creates them, give each a TeamColor listed here. Any team not
	listed falls back to DefaultVariant.
]]
CharacterSetup.TeamVariants = {
	["Neon orange"] = "Ember",
	["Bright orange"] = "Ember",
	["Really blue"] = "Steel",
	["Bright blue"] = "Steel",
}

function CharacterSetup.VariantFor(player: Player): string
	if player.Team and not player.Neutral then
		return CharacterSetup.TeamVariants[player.TeamColor.Name] or CharacterSetup.DefaultVariant
	end
	return CharacterSetup.DefaultVariant
end

-- ===========================================================================
-- Description
-- ===========================================================================

--[[
	A HumanoidDescription carrying the operator body and nothing else. Every
	accessory, clothing and animation field is left empty on purpose: this is
	what stops a player's own avatar items from reaching the character.
]]
function CharacterSetup.Description(variantName: string?): HumanoidDescription
	local variant = CharacterSetup.Variants[variantName or CharacterSetup.DefaultVariant]
		or CharacterSetup.Variants[CharacterSetup.DefaultVariant]

	local description = Instance.new("HumanoidDescription")
	for key, value in CharacterSetup.Scales do
		description[key] = value
	end

	-- Body colours only cover six regions (the R6 grouping), which is too
	-- coarse for gloves and boots. They are set here so the rig is roughly
	-- right from its first frame, and ApplyLook paints the exact regions.
	description.HeadColor = variant.Head
	description.TorsoColor = variant.Jacket
	description.LeftArmColor = variant.Jacket
	description.RightArmColor = variant.Jacket
	description.LeftLegColor = variant.Trousers
	description.RightLegColor = variant.Trousers

	if not CharacterSetup.ShowFace then
		description.Face = 0
	end

	return description
end

--[[
	Paints each part by outfit region and applies the shared materials.

	The BodyColors instance is removed first: it re-applies its six coarse
	colours whenever the rig reloads, which would paint the gloves and boots
	back to jacket and trouser colours.
]]
function CharacterSetup.ApplyLook(character: Model, variantName: string?)
	local variant = CharacterSetup.Variants[variantName or CharacterSetup.DefaultVariant]
		or CharacterSetup.Variants[CharacterSetup.DefaultVariant]

	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors:Destroy()
	end

	for partName, region in PART_REGIONS do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.Color = variant[region]
			part.Material = CharacterSetup.Materials[region]
		end
	end

	local head = character:FindFirstChild("Head")
	if head and not CharacterSetup.ShowFace then
		for _, child in head:GetChildren() do
			if child:IsA("Decal") and child.Name == "face" then
				child:Destroy()
			end
		end
	end

	character:SetAttribute("OverdriveVariant", variantName or CharacterSetup.DefaultVariant)
end

-- ===========================================================================
-- Hitboxes
--
-- One invisible part per R15 body part, sized from the SCALED part it covers
-- and welded to it, so shots register on the body players actually see.
--
-- Three collision groups keep them separate from physics and from the
-- visible mesh:
--   OverdriveBody    -- the visible parts. Normal physics; ignored by shots.
--   OverdriveHitbox  -- the hitboxes. Collide with nothing; hit only by shots.
--   OverdriveShot    -- the query group a gun raycasts with. Hits the world
--                       and hitboxes, never the visible mesh.
--
-- The point of the split is that the hitbox stays put while the visuals
-- change: a custom mesh, a helmet or a backpack later cannot move what a
-- bullet hits.
-- ===========================================================================

CharacterSetup.HitboxTag = "OverdriveHitbox"
CharacterSetup.HitboxPadding = 0 -- fraction added to each side; 0 = exactly the visible body

local GROUP_BODY = "OverdriveBody"
local GROUP_HITBOX = "OverdriveHitbox"
local GROUP_SHOT = "OverdriveShot"

CharacterSetup.CollisionGroups = {
	Body = GROUP_BODY,
	Hitbox = GROUP_HITBOX,
	Shot = GROUP_SHOT,
}

local groupsReady = false

-- Server only: collision groups are registered once per server.
function CharacterSetup.EnsureCollisionGroups()
	if groupsReady then
		return
	end
	assert(RunService:IsServer(), "CharacterSetup.EnsureCollisionGroups is server-only")

	for _, name in { GROUP_BODY, GROUP_HITBOX, GROUP_SHOT } do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end

	-- Hitboxes touch nothing but shots.
	for _, group in PhysicsService:GetRegisteredCollisionGroups() do
		PhysicsService:CollisionGroupSetCollidable(GROUP_HITBOX, group.name, false)
	end
	PhysicsService:CollisionGroupSetCollidable(GROUP_HITBOX, GROUP_SHOT, true)

	-- Shots pass through the visible body, so they can only land on a hitbox.
	PhysicsService:CollisionGroupSetCollidable(GROUP_SHOT, GROUP_BODY, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_SHOT, "Default", true)

	groupsReady = true
end

function CharacterSetup.BuildHitboxes(character: Model, ownerUserId: number?)
	for partName in PART_REGIONS do
		local part = character:FindFirstChild(partName)
		if not part or not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = GROUP_BODY

		local existing = part:FindFirstChild("Hitbox")
		if existing then
			existing:Destroy()
		end

		local hitbox = Instance.new("Part")
		hitbox.Name = "Hitbox"
		hitbox.Size = part.Size * (1 + CharacterSetup.HitboxPadding * 2)
		hitbox.CFrame = part.CFrame
		hitbox.Transparency = 1
		hitbox.CastShadow = false
		hitbox.CanCollide = false
		hitbox.CanTouch = false
		hitbox.CanQuery = true
		hitbox.Massless = true
		hitbox.Anchored = false
		hitbox.CollisionGroup = GROUP_HITBOX

		hitbox:SetAttribute("BodyPart", partName)
		hitbox:SetAttribute("Region", HIT_REGIONS[partName] or "Limb")
		if ownerUserId then
			hitbox:SetAttribute("OwnerUserId", ownerUserId)
		end

		local weld = Instance.new("WeldConstraint")
		weld.Name = "HitboxWeld"
		weld.Part0 = hitbox
		weld.Part1 = part
		weld.Parent = hitbox

		-- Parented under its body part, so it is always inside the character
		-- model and is cleaned up with it.
		hitbox.Parent = part
		CollectionService:AddTag(hitbox, CharacterSetup.HitboxTag)
	end

	-- The root capsule is movement collision, not something you can shoot.
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CollisionGroup = GROUP_BODY
	end
end

--[[
	What the gun system should raycast with. Hits world geometry and operator
	hitboxes; passes through the visible bodies. `ignore` is typically the
	shooter's own character.
]]
function CharacterSetup.HitboxRaycastParams(ignore: { Instance }?): RaycastParams
	local params = RaycastParams.new()
	params.CollisionGroup = GROUP_SHOT
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore or {}
	return params
end

-- ===========================================================================
-- Camera
-- ===========================================================================

--[[
	Roblox's default camera focuses on the root part plus a fixed offset:
	1.5 studs, plus however much the root part has grown past its default
	height. That lands at eye level on a default rig. On this taller body the
	head sits proportionally higher above the root, so without a correction the
	first-person eye would sit around the collarbone.

	The offset is measured from the actual rig rather than hard-coded, so it
	stays right if the proportions above are changed.
]]
local DEFAULT_CAMERA_LIFT = 1.5
local DEFAULT_ROOT_HEIGHT = 2
local EYE_ABOVE_HEAD_CENTRE = 0.12 -- fraction of head height

function CharacterSetup.CameraOffset(character: Model): Vector3
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not (root and head) then
		return Vector3.zero
	end

	local cameraFocusY = root.Position.Y + DEFAULT_CAMERA_LIFT + (root.Size.Y / 2 - DEFAULT_ROOT_HEIGHT / 2)
	local eyeY = head.Position.Y + head.Size.Y * EYE_ABOVE_HEAD_CENTRE
	return Vector3.new(0, eyeY - cameraFocusY, 0)
end

function CharacterSetup.AlignCamera(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.CameraOffset = CharacterSetup.CameraOffset(character)
	end
end

-- ===========================================================================
-- Entry points
-- ===========================================================================

--[[
	Everything a live, in-match operator needs once its rig exists: the look,
	hitboxes and camera alignment. Server-side, so it replicates to everyone.
]]
function CharacterSetup.Prepare(character: Model, variantName: string?, ownerUserId: number?)
	CharacterSetup.EnsureCollisionGroups()
	CharacterSetup.ApplyLook(character, variantName)
	CharacterSetup.BuildHitboxes(character, ownerUserId)
	CharacterSetup.AlignCamera(character)
	character:SetAttribute("OverdriveOperator", true)
end

--[[
	Spawns a player as an operator. NOT called by gameplay yet -- the match
	system will call this in place of player:LoadCharacter().

	Loading with the description (rather than loading the player's avatar and
	rescaling it after) means the character is correct from its first frame:
	no one sees a default-sized body pop up to full height.
]]
function CharacterSetup.Spawn(player: Player, variantName: string?)
	assert(RunService:IsServer(), "CharacterSetup.Spawn is server-only")

	local variant = variantName or CharacterSetup.VariantFor(player)
	player:LoadCharacterWithHumanoidDescription(CharacterSetup.Description(variant))

	local character = player.Character
	if character then
		CharacterSetup.Prepare(character, variant, player.UserId)
	end
	return character
end

--[[
	A standalone operator model for display: the lobby figure. Look only --
	no hitboxes, no collision groups -- so it is safe to build on the client.
]]
function CharacterSetup.BuildPreview(variantName: string?): Model
	local model = Players:CreateHumanoidModelFromDescription(
		CharacterSetup.Description(variantName),
		Enum.HumanoidRigType.R15
	)
	CharacterSetup.ApplyLook(model, variantName)
	return model
end

return CharacterSetup
