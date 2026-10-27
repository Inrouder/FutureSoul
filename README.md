# FUTURE / SOUL

**A cyberpunk, turn-based top-down tactical shooter made with Godot 4.4.1.** Original pixel-art tiles and character sprites; peer-to-peer LAN sessions with authoritative host-side rules.

> **Status: v0.1.0 prototype.** This is a small playable foundation, not a finished game. It is not a commercial release. The pictures provided in the original conversation are *visual references only*; no assets are copied from them.

## Art direction

![FutureSoul concept mock-up](docs/preview.png)

*Visual concept assembled from the game's original pixel sprites. It is not a screenshot from a running Godot build.*

The game runs at 1440×900 with 32×32 hand-drawn pixel art, high-contrast neon cyan / magenta interface elements, a dirty industrial tileset, console terminals, crates and hazard floors. The original PNGs are reproducible from `tools/build_art.py` with Pillow.

## Getting started

1. Install [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/).
2. Clone or download the repository.
3. Open `project.godot` in Godot and press **F6/F5** to run the main scene/project.
4. Select **Solo-Training / vs Bots** to play instantly, or **Host erstellen** and join with a second Godot instance for online PvP.
5. On a different computer, enter the host's LAN IPv4 address and select **Beitreten**. Network traffic uses **UDP 7777**. For Internet play you must forward this port (or use a VPN such as Tailscale); automatic matchmaking and NAT traversal are not implemented.

## Mode 01: Maelstrom Kidnap

- **Edgerunners (blue)**: Reach the hostage NPC in the right-side compound, select **Geisel**, then escape together through the luminous green extraction zone at the left.
- **Maelstrom (red)**: Prevent extraction for 12 rounds or eliminate the opposing squad.
- **Victory**: Blue wins with extraction or by eliminating the defending team. Red wins if all attackers die or the turn limit is exceeded.
- **Turn economy**: 3 action points per unit turn; move (1 AP, distance depends on class), fire (2 AP), secure hostage (1 AP), overwatch (1 AP), end turn (free).
- **Three classes**: Street Runner (95 HP, 5 steps), Netrunner (90 HP, 4 steps), Enforcer (130 HP, 3 steps).
- **Three weapons**: NEON-9 pistol, MANTIS AR rifle, STATIC SMG; each has separate range, accuracy and damage.
- **Cover / sightlines**: Solid props and walls block movement and gunfire; adjacency to cover reduces hit probability.
- **Bots**: Offline training supplies two simple host-controlled Maelstrom opponents. They move toward targets and fire when possible. Bots are intentionally basic.
- **PvP**: Godot ENet reliable RPC synchronizes participant profiles and the match state; only the host validates game actions, costs, hit rolls, victory conditions, movement paths and visibility.

**Controls:** Left click a tile/target; **1** move, **2** fire, **3** interact with hostage (when adjacent), **4** overwatch, **Space** end turn.

## Architecture

| Path | Purpose |
| --- | --- |
| `scenes/main.tscn` | Boot scene |
| `scripts/main.gd` | HUD, character editor, inputs, effects |
| `scripts/arena.gd` | Arena tiles, industrial set dressing, blockers and extraction zones |
| `scripts/actor.gd` | Pixel character visuals, HP and team rings |
| `scripts/game_rules.gd` | Pure turn rules, pathfinding, line of sight and weapon/class definitions |
| `scripts/match_controller.gd` | Multiplayer, authoritative simulation, rescue logic, turns and bots |
| `assets/tiles/` | Original 32×32 pixel environment sprites |
| `assets/units/` | Original 32×32 operator sprites, 4 palette options |
| `tools/build_art.py` | Regenerate the artwork using Python Pillow |
| `tests/rules_smoke.gd` | Headless game-rule smoke tests |

Run tests in Godot:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/rules_smoke.gd
```

## Next milestones

1. Multiplayer disconnection recovery, room codes, dedicated server and lobby ready states.
2. Full cover states, tactical fog of war, AP previews, weapon animations and richer environmental art.
3. Character accessories and layered outfit editor, more skills, character progression and unlocks.
4. Scenario editor with saved tile maps and scenarios, public/private map sharing.
5. NPC squad bots with cover seeking, rescue/defense strategies and difficulty levels.
6. Two additional game modes **to be specified by the project owner**; no unrequested modes are hardcoded.

## Rights

All generated pixel sprites and the source code included here were created for FutureSoul. Names and references such as “Maelstrom” and “Edgerunner” evoke an existing cyberpunk universe; the project is not affiliated with that franchise. For a standalone commercial game, adopt original faction names and independently commissioned artwork.
