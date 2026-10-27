# FutureSoul delivery plan

## Guiding vision
Top-down 2D Godot cyberpunk tactical PvP game with an atmospheric pixel-art city aesthetic. The screenshots supplied by the designer are visual references only, not assets to copy.

## Factions (10 classes)
- Maelstrom: Gunner (heavy machine gun/suppression), Punk Bruiser (smart-pistol + melee), Shooty (weapon modifications and aggressive gunfire).
- Edgerunners: The Big (heavy pistol), Snipeout (wall-piercing scope shot), Cyberpsycho (overdrive & mantis blades), Netrunner (EMP, weapon locks, monowire).
- Kobantec Dragon Clan: First Warrior (short invisibility, laser katana, suppressed sidearm); The Rocky (shield, tank and AOE bat); Raven (chain lightning and paired wall portals).

## Three required PvP modes
1. **Maelstrom Kidnap**: Maelstrom defend held NPC; Edgerunners enter, rescue, escort to extraction. Needs real hostage-following pathing and round-based timer. Current prototype has a static hostage marker and a simplified release/extraction check.
2. **Faction War**: symmetric two-base team fight. Current win condition is unit elimination; base capture rules can be added.
3. **Hack the Base**: extract codes at two enemy facilities with a matrix puzzle, then attack the mainframe. Current mission rules and matrix are present; network RPC hacking needs hardening.

## Implementation stages
1. **Playable slice (committed)**: input, AP turns, class picker, neon drawing, missions, bots, rudimentary LAN.
2. **Engine QA and robust architecture**: Godot import test, fix static parser/runtime issues, split core/render/UI/network into distinct modules; determinism, RPC validations, dedicated server multiplayer test.
3. **Art pass**: 32px/48px top-down animated hand-painted pixel sprites, cyberware, weapons, lighting, shadows, cyberpunk architecture, decals, neon billboards, weather, explosions; sprite & tileset licenses documented.
4. **Game depth**: cover, overwatch, suppression, line of sight fog, balanced stats, cooldowns, grenades, hostage-following, portal traversal, stealth, better NPC AI.
5. **Map editor**: in-game tile brush, object layers, spawn points, triggers, JSON level save, validation and map loading.
6. **Release**: lobby, faction/character loadout ownership per player, reconnection, sound design, accessibility, packaging, performance, QA & balance.

## Acceptance criteria
- Two independent Godot 4 clients can host/join and observe the same authoritative state after every action.
- All 10 class special skills implement their described mechanics, not just placeholder effects.
- Three modes reach their correct objective-based win conditions without softlocks.
- Hostage uses navigable NPC AI and escorts correctly.
- Pixel-art production assets render consistently, at native pixel resolution.
- A map built in the level editor can be saved, loaded and played.
- Automated logic tests and manual multiplayer test matrix run cleanly.
