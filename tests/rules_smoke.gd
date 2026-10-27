extends SceneTree

# Run: godot --headless --path . --script res://tests/rules_smoke.gd
func _initialize() -> void:
    var ok := true
    ok = _check(GameRules.in_bounds(Vector2i(3, 3)), "valid arena cell") and ok
    ok = _check(not GameRules.in_bounds(Vector2i(-1, 3)), "invalid arena cell") and ok
    ok = _check(GameRules.range_between(Vector2i(1, 2), Vector2i(5, 4)) == 6, "Manhattan distance") and ok
    ok = _check(GameRules.walk_distance(Vector2i(1, 1), Vector2i(3, 1), {}) == 2, "basic path") and ok
    var obstacle: Dictionary = {}
    obstacle[Vector2i(2, 1)] = true
    ok = _check(GameRules.walk_distance(Vector2i(1, 1), Vector2i(3, 1), obstacle) == 4, "obstacle detour") and ok
    ok = _check(GameRules.walk_distance(Vector2i(1, 1), Vector2i(2, 1), obstacle) == -1, "blocked target") and ok
    ok = _check(not GameRules.has_line_of_sight(Vector2i(1,1),Vector2i(4,1),obstacle),"blocked ray") and ok
    ok = _check(GameRules.has_line_of_sight(Vector2i(1,1),Vector2i(4,1),{}), "open ray") and ok
    ok = _check(GameRules.allowed_weapon("nonsense") == "rifle", "invalid weapon normalized") and ok
    print("FutureSoul game-rules smoke tests: ", "PASSED" if ok else "FAILED")
    quit(0 if ok else 1)

func _check(value: bool, label: String) -> bool:
    if not value:
        push_error("FAILED: " + label)
    return value
