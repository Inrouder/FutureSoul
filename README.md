# FUTURESOUL — Realtime Cyberpunk Shooter

Godot 4 realtime top-down action shooter. **The active main scene runs scripts/realtime.gd.** Previous scripts/game.gd is preserved as an archived turn-based experiment, not active gameplay.

## Play
1. Install Godot 4.3+ and import project.godot.
2. Run the game (F5).
3. Choose a mission, faction, class and armor tint; click DEPLOY / PLAY OFFLINE.

## Live controls
- WASD — move freely in real time.
- Mouse — aim; left click / hold — fire continuously.
- Space / right click — unique class skill with cooldown.
- E — interact with hostage/data terminals.
- Escape — return to menu. R — replay after match end.

## Modes (offline vertical slice)
- **Maelstrom Kidnap** — locate and rescue hostage, escort to turquoise extraction.
- **Faction War** — defeat six opposing fighters to clear their base.
- **Hack the Base** — interact with both DATA terminals before interacting with CORE.

Ten classes across Maelstrom, Edgerunners and Kobantec. NPC enemies move, aim, fire and chase in real time; two friendly combat bots support the player. Animated projectile tracers and spark particles, illustrated multi-part top-down soldiers, shadows, neon signage, cover crates and weathered industrial floor details.

## Honest limitations
The game is **an unverified realtime proof-of-concept**, not finished production-quality pixel art. A Godot executable is not installed in the current authoring environment so engine import/play testing could not be performed. Report the first Godot parser error with its line number if you encounter one. Networking/PvP is not yet implemented in the new realtime scene (old prototype includes experimental LAN scaffolding but is not active). Class skills are simplified; the hacking puzzle, Raven wall portals, robust multiplayer lobby, 2D tile asset pack, detailed animated sprites and level editor still require implementation. Placeholder industrial visuals should be replaced with an original pixel-art atlas to achieve the high-fidelity reference look.

The attached art references are stylistic inspiration, not reusable game assets.

## Roadmap
See docs/ROADMAP.md.
