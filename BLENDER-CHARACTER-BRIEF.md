# Overdrive — Blender character brief

Working notes for building the Overdrive operator as a real 3D model in
Blender, via the MCP for Blender integration. A new Claude Code session should
read this before touching Blender.

## Connection (done)

- MCP server registered for this project folder only: `uvx mcp-for-blender`
  (v2.1.0), with `DISABLE_TELEMETRY=true`.
- Blender 5.2, add-on `blender_mcp.py` installed in
  `%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\`.
- The add-on server listens on `127.0.0.1:9876` once **Start MCP Server** is
  clicked in the viewport sidebar (N) → **MCP for Blender** tab.
- Verified: a read-only scene query returned Blender's default scene (Cube,
  Light, Camera, 2 materials).
- Still to do: confirm the link again through the MCP tools themselves
  (get scene info) in the session that has them loaded.

## Rules from the user

- Build in stages: **base body → helmet → mask → gear**. After each stage,
  say what was done and take a viewport screenshot, then wait for feedback.
- **Ask before anything destructive**: deleting objects (including the default
  Cube, Light and Camera), or starting over.
- At the end, report the file location, every object name, and next steps for
  rigging and exporting to Roblox.

## The character

An **original** design — a generic modern tactical soldier, not a copy of any
existing game's character.

- Height equivalent to about 6–8 studs: tall and lean, not blocky.
- Full-coverage tactical helmet with side rails.
- Full-face respirator / gas mask covering nose and mouth, a separate object
  from the helmet.
- Plate carrier vest with a few pouches.
- Long-sleeve tactical shirt or jacket, tactical gloves.
- Cargo pants and boots.
- Realistic proportions: correct head-to-body ratio, defined shoulders, torso,
  arms and legs, hands with five fingers, feet.
- Low-to-medium poly and game-ready; it will be rigged and imported into
  Roblox later. No unnecessary geometry density.
- Separate objects for helmet, mask, vest, body, arms, legs, boots and gloves,
  so pieces can be adjusted or swapped.
- Simple base materials only, dark tactical palette. Real textures come later.

## Match the in-game operator

The Roblox side already has an operator body defined in
`src/ReplicatedStorage/Overdrive/CharacterSetup.luau`, and the mesh should
line up with it so it can replace it later:

- Height **7.66 studs**, about **8 heads tall**.
- Shoulders about 3.05 studs wide; hip height about 3.57 studs.
- It must end up as an **R15** rig with standard part names (Head, UpperTorso,
  LowerTorso, Left/Right UpperArm/LowerArm/Hand, Left/Right
  UpperLeg/LowerLeg/Foot), because tools, animations and the hitbox system in
  `CharacterSetup` depend on those names.
- Roblox now builds R15 characters with `AnimationConstraint` joints rather
  than `Motor6D`s — relevant when rigging and importing.

Confirm the Blender → Roblox unit scale during export rather than assuming it.
