--[[
	Items
	Every unlockable in the game, as data. One table per item.

	Shared between server and client: the client renders these tables, the
	server validates against them. Because the server re-reads the definition
	for every purchase and equip, a client cannot invent an item or a price.

	Adding content means adding a table here and nothing else.
]]

local Items = {}

-- ===========================================================================
-- Categories and loadout slots
-- ===========================================================================

Items.Category = {
	Gun = "Gun",
	GrappleSkin = "GrappleSkin",
	Emote = "Emote",
}

--[[
	Slots are what the Loadout tab shows. Each slot accepts one category.

	Guns are Warzone-style deploy weapons: you spawn holding them, and better
	guns are still found on the floor mid-match (see FloorLoot below). The
	secondary sling may be left empty on purpose -- deploying light and looting
	a sidearm on the way down is a real choice, so AllowEmpty is true there.
]]
Items.Slots = {
	Primary = {
		Key = "Primary",
		Label = "PRIMARY",
		Category = "Gun",
		Order = 1,
		AllowEmpty = false,
		Blurb = "Your deploy weapon.",
	},
	Secondary = {
		Key = "Secondary",
		Label = "SECONDARY",
		Category = "Gun",
		Order = 2,
		AllowEmpty = true,
		EmptyLabel = "EMPTY SLING",
		EmptyBlurb = "Deploy light and loot a second gun on the way down.",
		Blurb = "Your backup weapon.",
	},
	GrappleSkin = {
		Key = "GrappleSkin",
		Label = "GRAPPLE",
		Category = "GrappleSkin",
		Order = 3,
		AllowEmpty = false,
		Blurb = "How your line looks when you swing.",
	},
	Emote = {
		Key = "Emote",
		Label = "EMOTE",
		Category = "Emote",
		Order = 4,
		AllowEmpty = false,
		Blurb = "Played on a kill or on command.",
	},
}

Items.SlotOrder = { "Primary", "Secondary", "GrappleSkin", "Emote" }

-- ===========================================================================
-- Definitions
--
-- Every item shares: Id, Name, Category, Rarity, Price, UnlockLevel, Blurb.
--   Price 0 + UnlockLevel 1 + DefaultOwned  -> owned from the first login.
--   UnlockLevel > 1                         -> free once that level is hit.
--   Price > 0                               -> buyable earlier with OverCoins.
-- ===========================================================================

local DEFINITIONS = {
	-- --------------------------------------------------------------- guns ---
	{
		Id = "gun_vector",
		Name = "VECTOR SMG",
		Category = "Gun",
		Rarity = "Common",
		Price = 0,
		UnlockLevel = 1,
		DefaultOwned = true,
		Blurb = "Fast, forgiving, and brutal inside ten metres.",
		Class = "SMG",
		FloorLoot = true,
		Stats = { Damage = 22, FireRate = 900, Range = 45, Control = 72 },
	},
	{
		Id = "gun_ridgeline",
		Name = "RIDGELINE DMR",
		Category = "Gun",
		Rarity = "Rare",
		Price = 1200,
		UnlockLevel = 8,
		Blurb = "Punishes anyone who holds still on a rooftop.",
		Class = "DMR",
		FloorLoot = true,
		Stats = { Damage = 58, FireRate = 260, Range = 140, Control = 64 },
	},
	{
		Id = "gun_cinder",
		Name = "CINDER LMG",
		Category = "Gun",
		Rarity = "Epic",
		Price = 3000,
		UnlockLevel = 15,
		Blurb = "Holds a lane on its own. Bring patience.",
		Class = "LMG",
		FloorLoot = true,
		Stats = { Damage = 34, FireRate = 620, Range = 95, Control = 41 },
	},

	-- ------------------------------------------------------- grapple skins ---
	-- Visual is read by the grapple rope at runtime, so equipping a skin
	-- actually changes what the line looks like.
	{
		Id = "skin_standard",
		Name = "STANDARD CABLE",
		Category = "GrappleSkin",
		Rarity = "Common",
		Price = 0,
		UnlockLevel = 1,
		DefaultOwned = true,
		Blurb = "Braided steel. Does the job without asking questions.",
		Visual = {
			RopeColor = Color3.fromRGB(168, 172, 180),
			RopeMaterial = Enum.Material.Metal,
			RopeThickness = 0.14,
			HookColor = Color3.fromRGB(120, 124, 132),
			GlowColor = Color3.fromRGB(0, 0, 0),
			GlowStrength = 0,
			TrailColor = Color3.fromRGB(200, 204, 212),
			TrailTransparency = 0.75,
		},
	},
	{
		Id = "skin_neon_wire",
		Name = "NEON WIRE",
		Category = "GrappleSkin",
		Rarity = "Rare",
		Price = 900,
		UnlockLevel = 6,
		Blurb = "A line of cold light. Everyone sees where you went.",
		Visual = {
			RopeColor = Color3.fromRGB(40, 220, 255),
			RopeMaterial = Enum.Material.Neon,
			RopeThickness = 0.12,
			HookColor = Color3.fromRGB(180, 250, 255),
			GlowColor = Color3.fromRGB(40, 220, 255),
			GlowStrength = 1.4,
			TrailColor = Color3.fromRGB(40, 220, 255),
			TrailTransparency = 0.35,
		},
	},
	{
		Id = "skin_molten_chain",
		Name = "MOLTEN CHAIN",
		Category = "GrappleSkin",
		Rarity = "Legendary",
		Price = 4500,
		UnlockLevel = 20,
		Blurb = "Forged hot and never cooled. Leaves embers in the air.",
		Visual = {
			RopeColor = Color3.fromRGB(255, 96, 24),
			RopeMaterial = Enum.Material.Neon,
			RopeThickness = 0.18,
			HookColor = Color3.fromRGB(255, 190, 80),
			GlowColor = Color3.fromRGB(255, 120, 30),
			GlowStrength = 2,
			TrailColor = Color3.fromRGB(255, 150, 40),
			TrailTransparency = 0.2,
		},
	},

	-- ------------------------------------------------------------- emotes ---
	{
		Id = "emote_reload_flex",
		Name = "RELOAD FLEX",
		Category = "Emote",
		Rarity = "Common",
		Price = 0,
		UnlockLevel = 1,
		DefaultOwned = true,
		Blurb = "A slow reload, held a beat too long.",
		AnimationId = "rbxassetid://507770239",
		DurationSeconds = 2.4,
	},
	{
		Id = "emote_zero_g_spin",
		Name = "ZERO-G SPIN",
		Category = "Emote",
		Rarity = "Rare",
		Price = 750,
		UnlockLevel = 5,
		Blurb = "Mid-air, weightless, entirely on purpose.",
		AnimationId = "rbxassetid://507776043",
		DurationSeconds = 3.1,
	},
	{
		Id = "emote_overdrive_slam",
		Name = "OVERDRIVE SLAM",
		Category = "Emote",
		Rarity = "Epic",
		Price = 2200,
		UnlockLevel = 12,
		Blurb = "Ground-pound finish. The floor remembers it.",
		AnimationId = "rbxassetid://507777268",
		DurationSeconds = 2.8,
	},
}

-- ===========================================================================
-- Indexes, built once at require time
-- ===========================================================================

local byId = {}
local byCategory = {}
local defaultOwned = {}

for _, item in DEFINITIONS do
	assert(byId[item.Id] == nil, "Overdrive.Items: duplicate item id " .. item.Id)
	byId[item.Id] = item

	local bucket = byCategory[item.Category]
	if not bucket then
		bucket = {}
		byCategory[item.Category] = bucket
	end
	table.insert(bucket, item)

	if item.DefaultOwned then
		defaultOwned[item.Id] = true
	end
end

-- Cheapest and earliest first, so shop and loadout grids read as a ladder.
for _, bucket in byCategory do
	table.sort(bucket, function(a, b)
		if a.UnlockLevel ~= b.UnlockLevel then
			return a.UnlockLevel < b.UnlockLevel
		end
		if a.Price ~= b.Price then
			return a.Price < b.Price
		end
		return a.Name < b.Name
	end)
end

-- ===========================================================================
-- Lookups
-- ===========================================================================

function Items.Get(itemId: string?)
	if type(itemId) ~= "string" then
		return nil
	end
	return byId[itemId]
end

function Items.Exists(itemId: string?): boolean
	return Items.Get(itemId) ~= nil
end

-- Returns the shared, sorted list for a category. Treat it as read-only.
function Items.InCategory(category: string)
	return byCategory[category] or {}
end

function Items.All()
	return DEFINITIONS
end

-- Items every new profile starts with.
function Items.DefaultUnlocked()
	local set = {}
	for id in defaultOwned do
		set[id] = true
	end
	return set
end

-- The loadout a brand new player deploys with.
function Items.DefaultEquipped()
	return {
		Primary = "gun_vector",
		Secondary = "", -- empty sling by design; see Items.Slots.Secondary
		GrappleSkin = "skin_standard",
		Emote = "emote_reload_flex",
	}
end

-- ===========================================================================
-- Slot rules. Used by the server to validate an equip request, and by the
-- client to grey out cards -- one implementation, so they cannot disagree.
-- ===========================================================================

function Items.GetSlot(slotKey: string?)
	if type(slotKey) ~= "string" then
		return nil
	end
	return Items.Slots[slotKey]
end

--[[
	Can `itemId` go in `slotKey`, ignoring ownership?
	Returns false plus a player-facing reason when it cannot.
]]
function Items.CanSlotAccept(slotKey: string, itemId: string): (boolean, string?)
	local slot = Items.GetSlot(slotKey)
	if not slot then
		return false, "Unknown slot."
	end

	if itemId == "" or itemId == nil then
		if slot.AllowEmpty then
			return true
		end
		return false, slot.Label .. " cannot be left empty."
	end

	local item = Items.Get(itemId)
	if not item then
		return false, "That item does not exist."
	end

	if item.Category ~= slot.Category then
		return false, item.Name .. " does not fit the " .. slot.Label .. " slot."
	end

	return true
end

-- Primary and Secondary draw from the same pool, so a gun cannot be slung twice.
function Items.ConflictingSlot(slotKey: string): string?
	if slotKey == "Primary" then
		return "Secondary"
	elseif slotKey == "Secondary" then
		return "Primary"
	end
	return nil
end

-- ===========================================================================
-- Unlock requirements, phrased for the UI
-- ===========================================================================

--[[
	How this item can be obtained at `level`. Shape:
	{ Free, MeetsLevel, UnlockLevel, Price, Buyable, Requirement }
	`Requirement` is the one-line string a locked card shows.
]]
function Items.Requirement(itemId: string, level: number)
	local item = Items.Get(itemId)
	if not item then
		return nil
	end

	local meetsLevel = level >= item.UnlockLevel
	local free = item.Price <= 0
	local requirement

	if free then
		requirement = meetsLevel and "Unlocked at level " .. item.UnlockLevel
			or "Reach level " .. item.UnlockLevel
	elseif meetsLevel then
		requirement = "Free at this level"
	else
		requirement = "Level " .. item.UnlockLevel .. " or buy now"
	end

	return {
		Free = free,
		MeetsLevel = meetsLevel,
		UnlockLevel = item.UnlockLevel,
		Price = item.Price,
		Buyable = not free,
		Requirement = requirement,
	}
end

return Items
