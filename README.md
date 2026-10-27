# FUTURESOUL — Cyberpunk Tactical Warfare

A Godot 4 top-down, turn-based cyberpunk tactical shooter **early vertical slice**.

## Install & launch
1. Download/clone this repository.
2. Install Godot 4.3+ and import `project.godot`.
3. Press **F6/F5 / Run Project**. No third-party assets needed.

## Included
- **3 factions / 10 classes**: Maelstrom (Gunner, Punk Bruiser, Shooty), Edgerunners (The Big, Snipeout, Cyberpsycho, Netrunner) and Kobantec / Dragon Clan (First Warrior, Rocky, Raven).
- **3 rule sets**: Maelstrom Kidnap (hostage extraction), Faction War (team elimination) and Hack the Base (two terminals, then mainframe).
- AP turns, tactical movement and cover blockers, basic ranged damage and per-class special actions.
- Alternating code-matrix hacking minigame, unique faction-colored procedural sprites, HUD, character color/class picker, industrial neon arena.
- Basic offline bot turns and **experimental** ENet LAN host/join on UDP port 7777.

## Controls
- In menu select operation, faction, operative and suit color; then choose Solo / Host LAN / Join LAN.
- Left mouse: select friendly operative, move to floor tile, shoot target or interact with point of interest.
- 1 = Move; 2 = Shoot; 3 = Ability; 4 = Interact; Tab = next teammate; Space = end turn.
- Hack by selecting highlighted goal codes in alternating column and row order (first move is on top row).
- Esc = leave minigame / return to HQ.
- To join a game, edit the IP address at the bottom of the main menu; default 127.0.0.1.

## Current limitations (read before use)
This is NOT a finished, tested multiplayer release. Godot was unavailable in the authoring environment; importing, gameplay testing, and live two-machine multiplayer tests are **still required**. This code has been source-reviewed, but no successful engine run is claimed. LAN sync is experimental; remote team selection and the hacking RPC flow require integration hardening. Internet play requires UDP port forwarding/firewall configuration. No account system, matchmaking, server anti-cheat, replay, or save/load.

**Graphics are intentionally self-drawn, procedurally stylized starter artwork, not professional finished pixel-art sprites.** The reference game's protected assets are not included. The level editor, hand-authored tiles, sound, animation atlas, portal wall traversal, full hostage-following AI, and sophisticated cover/pathfinding are planned and not yet implemented.

## Architecture
`project.godot` entry point → `main.tscn` → `scripts/game.gd`.

Roadmap is documented in [docs/ROADMAP.md](docs/ROADMAP.md).
