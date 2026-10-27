extends SceneTree

# End-to-end host-authoritative scenario tests without a graphical window.
func _initialize() -> void:
    call_deferred("_run_cases")

func _run_cases() -> void:
    var passed := true
    var arena := FutureArena.new()
    root.add_child(arena)
    var game := MatchController.new()
    game.arena = arena
    root.add_child(game)

    game.selected_mode = "skirmish"
    game.start_training()
    passed = _check(game.state["phase"] == "battle", "skirmish starts with bot opposition") and passed
    passed = _check(game.state["mode"] == "skirmish", "skirmish selected") and passed
    var before: int = int(game.state["players"][1]["ap"])
    game.issue_action("breach|[]", Vector2i(23, 6))
    passed = _check(int(game.state["players"][1]["ap"]) == before, "hacks forbidden outside hacking mode") and passed

    game.selected_mode = "hack"
    game.start_training()
    passed = _check(game.state["mode"] == "hack", "hacking operation selected") and passed
    var operator: Dictionary = game.state["players"][1]
    operator["pos"] = Vector2i(23, 7)
    game.state["players"][1] = operator
    game.issue_action("breach|[]", Vector2i(23, 6))
    passed = _check(game.state["hacked"]["edge"].size() == 0, "host rejects forged solution") and passed
    game.issue_action("breach|" + JSON.stringify(BreachRules.reference_path(0)), Vector2i(23, 6))
    passed = _check(game.state["hacked"]["edge"].has(0), "first enemy code acquired") and passed

    operator = game.state["players"][1]
    operator["pos"] = Vector2i(24, 9)
    game.state["players"][1] = operator
    game.issue_action("breach|" + JSON.stringify(BreachRules.reference_path(1)), Vector2i(24, 10))
    passed = _check(game.state["hacked"]["edge"].has(1), "second enemy code acquired") and passed
    game.issue_action("breach|" + JSON.stringify(BreachRules.reference_path(2)), Vector2i(23, 9))
    passed = _check(game.state["phase"] == "victory" and game.state["winner"] == "edge", "mainframe attack ends match") and passed

    game.selected_mode = "kidnap"
    game.start_training()
    operator = game.state["players"][1]
    operator["pos"] = Vector2i(22, 10)
    game.state["players"][1] = operator
    game.issue_action("interact")
    passed = _check(int(game.state["carrier"]) == 1, "hostage picked up") and passed
    operator = game.state["players"][1]
    operator["pos"] = Vector2i(5, 9)
    game.state["players"][1] = operator
    game.issue_action("move", Vector2i(4, 9))
    passed = _check(game.state["phase"] == "victory" and game.state["winner"] == "edge", "hostage extracted") and passed

    print("FutureSoul scenario smoke tests: ", "PASSED" if passed else "FAILED")
    quit(0 if passed else 1)

func _check(value: bool, label: String) -> bool:
    if not value:
        push_error("FAILED: " + label)
    return value
