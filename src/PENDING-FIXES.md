# Overdrive source mirror — status

Place: **Place1**, `placeId 80519094132218` (saved + published). Studio is the
source of truth; this folder is a backup copy.

## Mirror status: partial

Mirrored and matching Studio as of the operator character:

- `ReplicatedStorage/Overdrive/CharacterSetup.luau` — the operator body
- `ReplicatedStorage/Overdrive/Config.luau`
- `ReplicatedStorage/Overdrive/Items.luau`
- `ReplicatedStorage/Overdrive/Signal.luau`
- `StarterPlayerScripts/Overdrive/MenuAvatar.luau`

Not yet mirrored (27 modules): `Net`, `Profile`, all nine
`ServerScriptService/Overdrive` services, and the remaining
`StarterPlayerScripts/Overdrive` modules, components and screens.

## Operator character — not wired into gameplay yet

`CharacterSetup.Spawn(player)` is built and tested but nothing calls it.
Match characters still spawn as each player's Roblox avatar until the match
mechanics are built. To switch over, replace the two `player:LoadCharacter()`
calls in `ServerScriptService/Overdrive/SpawnService` with
`CharacterSetup.Spawn(player)`, and set
`StarterPlayer.LoadCharacterAppearance = false`.

## Why it stopped

Copying source through the assistant costs the full text twice (once to read
it out of Studio, once to write it here). Two cheaper routes exist:

1. **File → Save to File As → `Overdrive.rbxlx`** in the project folder. A
   complete, text-based backup of every script *and* the menu stage, diffable
   in git, and one click.
2. Temporarily enable **Home → Game Settings → Security → Allow HTTP
   Requests**. Studio can then push every script to a local receiver in a
   single call, after which the setting is switched back off.

## Previously pending fixes — all applied

- `AvatarRing` cylinder axis (it rendered as a 9-stud pillar)
- Camera cropping the figure's feet (`Distance = 17`, `LookHeight = 2.6`)
