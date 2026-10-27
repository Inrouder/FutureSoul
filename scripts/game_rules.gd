class_name GameRules
extends RefCounted

# Pure game rules. The host is the only authority permitted to apply actions.
const WIDTH := 28
const HEIGHT := 19
const MAX_ROUNDS := 12
const AP_PER_TURN := 3
const MODES := {
    "kidnap": "MAELSTROM KIDNAP",
    "skirmish": "BASE VS BASE",
    "hack": "HACK THE BASE",
}
const FACTIONS := {
    "maelstrom": "MAELSTROM PUNKS",
    "edgerunner": "EDGERUNNERS",
    "kobantec": "KOBANTEC / DRAGON CLAN",
}
const WEAPONS := {
    "pistol": {"label": "NEON-9", "damage": 32, "range": 8, "accuracy": 87},
    "rifle": {"label": "MANTIS AR", "damage": 42, "range": 11, "accuracy": 79},
    "smg": {"label": "STATIC SMG", "damage": 30, "range": 7, "accuracy": 90},
    "hmg": {"label": "IRONSTORM HMG", "damage": 52, "range": 9, "accuracy": 70},
    "smart": {"label": "SMARTSIDE", "damage": 34, "range": 7, "accuracy": 94},
    "punkgun": {"label": "SAWED-OFF", "damage": 55, "range": 4, "accuracy": 84},
    "bigiron": {"label": "BIG IRON .80", "damage": 64, "range": 7, "accuracy": 78},
    "sniper": {"label": "GHOST RAIL", "damage": 62, "range": 16, "accuracy": 85},
    "mantis": {"label": "MANTIS BLADES", "damage": 51, "range": 2, "accuracy": 98},
    "wire": {"label": "MONOWIRE", "damage": 35, "range": 5, "accuracy": 96},
    "katana": {"label": "LASER KATANA", "damage": 58, "range": 2, "accuracy": 97},
    "bat": {"label": "SHOCK BAT", "damage": 44, "range": 2, "accuracy": 94},
    "arc": {"label": "ARC LINK", "damage": 38, "range": 7, "accuracy": 93},
}
const CLASSES := {
    "m_gunner": {"label": "GUNNER", "faction": "maelstrom", "movement": 3, "health": 150, "weapon": "hmg", "skill": "SUPPRESSION"},
    "m_brawler": {"label": "PUNK SCHLAEGER", "faction": "maelstrom", "movement": 5, "health": 115, "weapon": "smart", "skill": "BERSERK STRIKE"},
    "m_shooty": {"label": "SHOOTY", "faction": "maelstrom", "movement": 4, "health": 105, "weapon": "punkgun", "skill": "DOUBLE TAP"},
    "e_big": {"label": "THE BIG", "faction": "edgerunner", "movement": 4, "health": 130, "weapon": "bigiron", "skill": "POWER SHOT"},
    "e_sniper": {"label": "THE SNIPEOUT", "faction": "edgerunner", "movement": 4, "health": 85, "weapon": "sniper", "skill": "WALL PENETRATION"},
    "e_psycho": {"label": "CYBERPSYCHO", "faction": "edgerunner", "movement": 6, "health": 115, "weapon": "mantis", "skill": "OVERDRIVE"},
    "e_runner": {"label": "NETRUNNER", "faction": "edgerunner", "movement": 5, "health": 88, "weapon": "wire", "skill": "WEAPON JAM"},
    "k_first": {"label": "FIRST WARRIOR", "faction": "kobantec", "movement": 5, "health": 108, "weapon": "katana", "skill": "GHOST CLOAK"},
    "k_rocky": {"label": "THE ROCKY", "faction": "kobantec", "movement": 4, "health": 180, "weapon": "bat", "skill": "SHIELD BASH"},
    "k_raven": {"label": "RAVEN", "faction": "kobantec", "movement": 5, "health": 95, "weapon": "arc", "skill": "CHAIN LIGHTNING"},
    # Compatibility with prototype profiles.
    "runner": {"label": "STREET RUNNER", "faction": "edgerunner", "movement": 5, "health": 95, "weapon": "rifle", "skill": "DASH"},
    "netrunner": {"label": "NETRUNNER (LEGACY)", "faction": "edgerunner", "movement": 4, "health": 90, "weapon": "pistol", "skill": "WEAPON JAM"},
    "heavy": {"label": "ENFORCER (LEGACY)", "faction": "maelstrom", "movement": 3, "health": 130, "weapon": "hmg", "skill": "SUPPRESSION"},
}
static func classes_for_faction(faction: String) -> Array:
    var values: Array = []
    for id in CLASSES:
        if str(CLASSES[id].get("faction", "")) == faction and not id in ["runner", "netrunner", "heavy"]:
            values.append(id)
    return values

static func valid_faction(value: String) -> String:
    return value if FACTIONS.has(value) else "edgerunner"

static func valid_mode(value: String) -> String:
    return value if MODES.has(value) else "kidnap"

static func in_bounds(c: Vector2i) -> bool:
    return c.x >= 0 and c.y >= 0 and c.x < WIDTH and c.y < HEIGHT

static func range_between(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)

static func walk_distance(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> int:
    if not in_bounds(goal) or blocked.has(goal):
        return -1
    if start == goal:
        return 0
    var visited: Dictionary = {}
    visited[start] = true
    var queue: Array[Vector2i] = [start]
    var steps: Array[int] = [0]
    var index := 0
    const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    while index < queue.size():
        var pos := queue[index]
        var n := steps[index] + 1
        index += 1
        for direction in DIRS:
            var candidate := pos + direction
            if not in_bounds(candidate) or visited.has(candidate) or blocked.has(candidate):
                continue
            if candidate == goal:
                return n
            visited[candidate] = true
            queue.append(candidate)
            steps.append(n)
    return -1

static func has_line_of_sight(start: Vector2i, goal: Vector2i, obstacles: Dictionary) -> bool:
    # Bresenham grid ray. Blocking tiles between shooter and target hide the target.
    var x := start.x
    var y := start.y
    var dx: int = absi(goal.x - x)
    var dy: int = absi(goal.y - y)
    var sx := 1 if x < goal.x else -1
    var sy := 1 if y < goal.y else -1
    var error: int = dx - dy
    while x != goal.x or y != goal.y:
        var double_error: int = 2 * error
        if double_error > -dy:
            error -= dy
            x += sx
        if double_error < dx:
            error += dx
            y += sy
        var probe := Vector2i(x, y)
        if probe != goal and obstacles.has(probe):
            return false
    return true

static func blockers_on_ray(start: Vector2i, goal: Vector2i, obstacles: Dictionary) -> int:
    var x := start.x
    var y := start.y
    var dx := abs(goal.x - x)
    var dy := abs(goal.y - y)
    var sx := 1 if x < goal.x else -1
    var sy := 1 if y < goal.y else -1
    var error := dx - dy
    var count := 0
    while x != goal.x or y != goal.y:
        var twice := 2 * error
        if twice > -dy:
            error -= dy
            x += sx
        if twice < dx:
            error += dx
            y += sy
        var probe := Vector2i(x, y)
        if probe != goal and obstacles.has(probe):
            count += 1
    return count

static func allowed_class(value: String) -> String:
    return value if CLASSES.has(value) else "runner"

static func allowed_weapon(value: String) -> String:
    return value if WEAPONS.has(value) else "rifle"

static func class_for_unit(unit: Dictionary) -> Dictionary:
    return CLASSES.get(str(unit.get("class_id", "runner")), CLASSES["runner"])

static func weapon_for_unit(unit: Dictionary) -> Dictionary:
    return WEAPONS.get(str(unit.get("weapon", "rifle")), WEAPONS["rifle"])
