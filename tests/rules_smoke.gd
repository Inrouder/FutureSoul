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
    ok = _check(GameRules.MODES.size() == 3, "all three tactical modes present") and ok
    ok = _check(GameRules.classes_for_faction("maelstrom").size() == 3, "maelstrom three specialists") and ok
    ok = _check(GameRules.classes_for_faction("edgerunner").size() == 4, "edgerunner four specialists") and ok
    ok = _check(GameRules.classes_for_faction("kobantec").size() == 3, "dragon clan three specialists") and ok
    ok = _check(GameRules.blockers_on_ray(Vector2i(1, 1), Vector2i(4, 1), obstacle) == 1, "one-wall rail shot") and ok
    for terminal in range(3):
        var solution := BreachRules.reference_path(terminal)
        ok = _check(BreachRules.path_is_valid(terminal, solution), "solvable hack node %d" % terminal) and ok
        var corrupted: Array = solution.duplicate(true)
        corrupted[1] = [4, 4] if solution[1] != [4, 4] else [0, 4]
        ok = _check(not BreachRules.path_is_valid(terminal, corrupted), "tampered hack proof rejected %d" % terminal) and ok
    ok = _check(not BreachRules.path_is_valid(0, []), "empty hack proof rejected") and ok
    print("FutureSoul game-rules smoke tests: ", "PASSED" if ok else "FAILED")
    quit(0 if ok else 1)

func _check(value: bool, label: String) -> bool:
    if not value:
        push_error("FAILED: " + label)
    return value
