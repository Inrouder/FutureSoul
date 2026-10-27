class_name GameRules
extends RefCounted

# Pure game rules. The host is the only authority permitted to apply actions.
const WIDTH := 28
const HEIGHT := 19
const MAX_ROUNDS := 12
const AP_PER_TURN := 3
const WEAPONS := {
    "pistol": {"label": "NEON-9", "damage": 34, "range": 8, "accuracy": 88},
    "rifle": {"label": "MANTIS AR", "damage": 43, "range": 11, "accuracy": 78},
    "smg": {"label": "STATIC SMG", "damage": 29, "range": 7, "accuracy": 94},
}
const CLASSES := {
    "runner": {"label": "STREET RUNNER", "movement": 5, "health": 95},
    "netrunner": {"label": "NETRUNNER", "movement": 4, "health": 90},
    "heavy": {"label": "ENFORCER", "movement": 3, "health": 130},
}

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
    var dx := abs(goal.x - x)
    var dy := abs(goal.y - y)
    var sx := 1 if x < goal.x else -1
    var sy := 1 if y < goal.y else -1
    var error := dx - dy
    while x != goal.x or y != goal.y:
        var double_error := 2 * error
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

static func allowed_class(value: String) -> String:
    return value if CLASSES.has(value) else "runner"

static func allowed_weapon(value: String) -> String:
    return value if WEAPONS.has(value) else "rifle"

static func class_for_unit(unit: Dictionary) -> Dictionary:
    return CLASSES.get(str(unit.get("class_id", "runner")), CLASSES["runner"])

static func weapon_for_unit(unit: Dictionary) -> Dictionary:
    return WEAPONS.get(str(unit.get("weapon", "rifle")), WEAPONS["rifle"])
