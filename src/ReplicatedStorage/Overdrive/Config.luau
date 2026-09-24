--[[
	Config
	Every tuning value for Overdrive lives here: palette, motion, economy,
	progression, rate limits, DataStore behaviour and match rules.

	Nothing in here reads from the DataModel, so both the server and the client
	can require it safely and cheaply.
]]

local Config = {}

-- ===========================================================================
-- Identity
-- ===========================================================================

Config.GameName = "OVERDRIVE"
Config.Tagline = "Grapple. Shoot. Never stop."

-- ===========================================================================
-- Economy
-- ===========================================================================

Config.Currency = {
	Name = "OverCoins",
	Short = "OC",
}

Config.StartingCurrency = 500

-- ===========================================================================
-- Progression
--
-- Total XP is the authoritative saved value; level is derived from it on load
-- so the two can never drift apart. XP needed to go from level n to n+1 is
-- BaseXp + XpPerLevel * (n - 1), i.e. each level costs a little more.
-- ===========================================================================

Config.Progression = {
	BaseXp = 800,
	XpPerLevel = 400,
	MaxLevel = 100,
}

-- XP required to advance from `level` to `level + 1`.
function Config.XpToNextLevel(level: number): number
	if level >= Config.Progression.MaxLevel then
		return math.huge
	end
	return Config.Progression.BaseXp + Config.Progression.XpPerLevel * (level - 1)
end

-- Cumulative XP required to *be* at `level`. Level 1 costs nothing.
function Config.TotalXpForLevel(level: number): number
	level = math.clamp(level, 1, Config.Progression.MaxLevel)
	local steps = level - 1
	return steps * (Config.Progression.BaseXp + (Config.Progression.XpPerLevel * (steps - 1)) / 2)
end

-- Derives level plus progress-within-level from a total XP value.
function Config.ResolveLevel(totalXp: number)
	totalXp = math.max(0, math.floor(totalXp or 0))

	local level = 1
	while level < Config.Progression.MaxLevel and totalXp >= Config.TotalXpForLevel(level + 1) do
		level += 1
	end

	local floorXp = Config.TotalXpForLevel(level)
	local needed = Config.XpToNextLevel(level)
	local into = totalXp - floorXp

	if needed == math.huge then
		return level, 0, 0, 1 -- max level: bar reads full
	end

	return level, into, needed, math.clamp(into / needed, 0, 1)
end

-- ===========================================================================
-- Visual theme
-- ===========================================================================

Config.Theme = {
	-- Surfaces, darkest to lightest.
	Void = Color3.fromRGB(6, 6, 8),
	Background = Color3.fromRGB(12, 12, 15),
	Surface = Color3.fromRGB(21, 22, 26),
	SurfaceRaised = Color3.fromRGB(30, 32, 38),
	SurfaceHover = Color3.fromRGB(40, 43, 50),
	Stroke = Color3.fromRGB(52, 56, 65),
	StrokeBright = Color3.fromRGB(86, 92, 104),

	-- The hot accent ramp. Accent is the brand colour; AccentHot is used for
	-- gradient ends, glows and pressed states.
	Accent = Color3.fromRGB(255, 88, 20),
	AccentHot = Color3.fromRGB(233, 30, 35),
	AccentSoft = Color3.fromRGB(255, 140, 70),

	-- Text.
	TextPrimary = Color3.fromRGB(246, 246, 250),
	TextSecondary = Color3.fromRGB(176, 181, 194),
	TextMuted = Color3.fromRGB(116, 122, 136),
	TextOnAccent = Color3.fromRGB(255, 255, 255),

	-- Status.
	Success = Color3.fromRGB(58, 214, 132),
	Warning = Color3.fromRGB(255, 190, 60),
	Danger = Color3.fromRGB(255, 78, 78),
	Locked = Color3.fromRGB(92, 98, 112),
}

Config.Rarity = {
	Order = { "Common", "Rare", "Epic", "Legendary" },
	Common = { Label = "COMMON", Color = Color3.fromRGB(150, 158, 172) },
	Rare = { Label = "RARE", Color = Color3.fromRGB(64, 156, 255) },
	Epic = { Label = "EPIC", Color = Color3.fromRGB(186, 96, 255) },
	Legendary = { Label = "LEGENDARY", Color = Color3.fromRGB(255, 176, 42) },
}

function Config.RarityInfo(rarity: string)
	return Config.Rarity[rarity] or Config.Rarity.Common
end

Config.Fonts = {
	-- Montserrat Black reads as a game-logo face and ships with Roblox.
	Display = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy),
	Heading = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
	Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	BodyBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	Numeric = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
}

-- ===========================================================================
-- Motion
--
-- Roblox cannot shear a TextLabel, so the "slanted" look is produced by
-- rotating whole elements by SlantDegrees and tracking the logo letters out
-- manually. Keeping the angle here means every surface leans the same way.
-- ===========================================================================

Config.Motion = {
	Instant = 0.08,
	Fast = 0.14,
	Normal = 0.24,
	Slow = 0.42,
	ScreenSwap = 0.3,
	BootFade = 0.55,
	DeployFade = 0.45,

	Ease = Enum.EasingStyle.Quint,
	EaseDirection = Enum.EasingDirection.Out,
	BackEase = Enum.EasingStyle.Back,

	SlantDegrees = -3,
	HoverLiftPixels = 5,
	HoverScale = 1.03,
	PressScale = 0.965,
}

-- ===========================================================================
-- Sounds
--
-- Every id here is a built-in Roblox asset that was confirmed to load
-- (Sound.IsLoaded true with a non-zero TimeLength), so none of these are
-- silent placeholders. Pitch and volume are tuned per cue.
-- ===========================================================================

Config.Sounds = {
	Hover = { Id = "rbxasset://sounds/switch.wav", Volume = 0.22, Pitch = 1.45 },
	Click = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.4, Pitch = 1.1 },
	Tab = { Id = "rbxasset://sounds/switch3.wav", Volume = 0.35, Pitch = 1.15 },
	Unlock = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1 },
	Refused = { Id = "rbxasset://sounds/metal.ogg", Volume = 0.3, Pitch = 0.7 },
	Deploy = { Id = "rbxasset://sounds/bass.wav", Volume = 0.55, Pitch = 0.9 },
	LevelUp = { Id = "rbxasset://sounds/victory.wav", Volume = 0.5, Pitch = 1 },
	Equip = { Id = "rbxasset://sounds/snap.wav", Volume = 0.35, Pitch = 1.2 },
}

-- ===========================================================================
-- Layout
--
-- The UI is authored against a 1920x1080 frame and scaled by a single UIScale
-- at the root, so one set of pixel sizes works on every device. Phones and
-- tablets get a deliberate boost: a literal proportional shrink leaves text
-- and touch targets far too small on a handset.
-- ===========================================================================

Config.Layout = {
	BaseHeight = 1080,
	MinScale = 0.5,
	MaxScale = 1.35,
	PhoneMaxWidth = 700,
	TabletMaxWidth = 1100,
	PhoneScaleBoost = 1.55,
	TabletScaleBoost = 1.3,
	ScreenPadding = 28,
	MinTouchTarget = 44, -- pixels, before scaling

	--[[
		Phones get their own clamp rather than sharing the desktop one.

		Scaling off viewport height alone breaks on a landscape handset, which is
		how most Roblox mobile play actually happens: 812x375 would produce a
		scale near 0.35 and text around 5px. The floor keeps text legible there.
		The ceiling exists because a 268px item card has to fit inside a 375px
		portrait screen -- above roughly 1.15 it no longer does.
	]]
	PhoneMinScale = 0.75,
	PhoneMaxScale = 1.15,
}

-- ===========================================================================
-- Menu camera (slow orbit over the placeholder stage)
-- ===========================================================================

Config.MenuCamera = {
	StageName = "MenuStage",
	OrbitRadius = 54,
	OrbitHeight = 22,
	OrbitSeconds = 90, -- one full revolution
	LookHeight = 6,
	FieldOfView = 62,
	DriftAmplitude = 2.5, -- gentle vertical bob
	DriftSeconds = 11,
}

-- ===========================================================================
-- Player settings: ranges are enforced on the server, not just the slider.
-- ===========================================================================

Config.SettingsSpec = {
	Sensitivity = { Default = 0.5, Min = 0.05, Max = 2, Step = 0.05, Label = "MOUSE SENSITIVITY" },
	FieldOfView = { Default = 80, Min = 60, Max = 110, Step = 1, Label = "FIELD OF VIEW" },
	MasterVolume = { Default = 0.8, Min = 0, Max = 1, Step = 0.05, Label = "MASTER VOLUME" },
	MusicVolume = { Default = 0.45, Min = 0, Max = 1, Step = 0.05, Label = "MUSIC VOLUME" },
	Crosshair = { Default = "Cross", Options = { "Cross", "Dot", "Chevron", "Brackets" }, Label = "CROSSHAIR" },
}

-- ===========================================================================
-- Match modes
--
-- Death routing depends on the mode: elimination modes send the player back
-- to the dashboard, respawn modes drop them straight back into the fight.
-- The match system does not exist yet; SpawnService reads CurrentMode so the
-- behaviour is already correct once it does.
-- ===========================================================================

Config.MatchModes = {
	BattleRoyale = {
		Label = "BATTLE ROYALE",
		ReturnToDashboardOnDeath = true,
		RespawnDelay = 0,
	},
	TeamDeathmatch = {
		Label = "TEAM DEATHMATCH",
		ReturnToDashboardOnDeath = false,
		RespawnDelay = 3.5,
	},
}

Config.DefaultMatchMode = "TeamDeathmatch"

-- ===========================================================================
-- Rate limits: Tokens requests allowed per Window seconds, per player.
-- ===========================================================================

Config.RateLimits = {
	Default = { Tokens = 8, Window = 10 },
	RequestPlay = { Tokens = 4, Window = 6 },
	RequestPurchase = { Tokens = 6, Window = 10 },
	RequestEquip = { Tokens = 12, Window = 10 },
	RequestSettings = { Tokens = 10, Window = 10 },
}

-- ===========================================================================
-- Persistence
-- ===========================================================================

Config.Data = {
	StoreName = "Overdrive_PlayerData",
	StoreVersion = 1,
	KeyPrefix = "player_",

	AutosaveInterval = 120,
	AutosaveJitter = 25, -- spreads saves out so they do not all fire together

	LoadAttempts = 5,
	SaveAttempts = 4,
	RetryBaseDelay = 1.5, -- exponential: 1.5, 3, 6, 12...
	RetryMaxDelay = 20,

	-- A session lock stops two servers writing the same profile. If a lock is
	-- older than this the owning server is assumed dead and the lock is taken.
	SessionLockStaleAfter = 90,
	SessionLockWaitAttempts = 6,
	SessionLockWaitDelay = 3,
}

return Config
