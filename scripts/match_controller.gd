class_name MatchController
extends Node

signal updated
signal status(message: String)

const PORT := 7777
const MAX_PEERS := 7
const BLUE_SPAWNS := [Vector2i(3, 14), Vector2i(4, 15), Vector2i(3, 6), Vector2i(6, 16)]
const RED_SPAWNS := [Vector2i(24, 4), Vector2i(24, 6), Vector2i(23, 14), Vector2i(24, 16)]
const HOSTAGE_START := Vector2i(22, 9)

var arena: FutureArena
var state: Dictionary = {}
var my_profile: Dictionary = {"name": "GHOST_01", "team": "edge", "class_id": "runner", "color_id": 0, "weapon": "rifle"}
var local_id := 1
var rng := RandomNumberGenerator.new()
var bot_working := false

func _ready() -> void:
    rng.randomize()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    reset_state()

func reset_state() -> void:
    state = {"phase": "menu", "players": {}, "turn_order": [], "turn_index": 0, "active": 0, "round": 1, "hostage": HOSTAGE_START, "carrier": 0, "winner": "", "event": {}, "log": ["SYSTEM // Link initialized"], "training": false}
    updated.emit()

func _default_player(id: int, incoming: Dictionary, team: String) -> Dictionary:
    return {"id": id, "name": str(incoming.get("name", "GHOST")).substr(0, 15), "team": team, "class_id": GameRules.allowed_class(str(incoming.get("class_id", "runner"))), "color_id": clampi(int(incoming.get("color_id", 0)), 0, 3), "weapon": GameRules.allowed_weapon(str(incoming.get("weapon", "rifle"))), "hp": 100, "ap": 0, "pos": Vector2i.ZERO, "alive": true, "overwatch": false, "bot": false}

func start_host() -> void:
    _disconnect_peer()
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_server(PORT, MAX_PEERS)
    if result != OK:
        status.emit("HOST ERROR // Port %d ist nicht verfügbar" % PORT)
        return
    multiplayer.multiplayer_peer = peer
    local_id = 1
    my_profile["team"] = "edge"
    reset_state()
    state["phase"] = "lobby"
    state["players"][1] = _default_player(1, my_profile, "edge")
    _log("HOST ONLINE // UDP %d" % PORT)
    _publish()

func start_join(ip: String) -> void:
    _disconnect_peer()
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_client(ip.strip_edges(), PORT)
    if result != OK:
        status.emit("CONNECT ERROR // Adresse oder Verbindung fehlerhaft")
        return
    multiplayer.multiplayer_peer = peer
    reset_state()
    state["phase"] = "connecting"
    status.emit("CONNECTING // %s:%d" % [ip, PORT])
    updated.emit()

func start_training() -> void:
    _disconnect_peer()
    local_id = 1
    my_profile["team"] = "edge"
    reset_state()
    state["phase"] = "lobby"
    state["training"] = true
    state["players"][1] = _default_player(1, my_profile, "edge")
    for index in range(2):
        var id := -10 - index
        var bot := _default_player(id, {"name": "MAELSTROM_%02d" % (index+1), "class_id": "heavy" if index == 0 else "runner", "weapon": "smg", "color_id": 3}, "punk")
        bot["bot"] = true
        state["players"][id] = bot
    _begin_battle()

func _disconnect_peer() -> void:
    if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _on_connected() -> void:
    local_id = multiplayer.get_unique_id()
    var initial := my_profile.duplicate()
    initial.erase("team") # Keep the team the host assigned automatically.
    send_profile.rpc_id(1, initial)
    status.emit("LINK ESTABLISHED // Peer #%d" % local_id)

func _on_connection_failed() -> void:
    _disconnect_peer()
    reset_state()
    status.emit("VERBINDUNG FEHLGESCHLAGEN // Host nicht erreichbar")

func _on_server_disconnected() -> void:
    _disconnect_peer()
    reset_state()
    status.emit("HOST OFFLINE // Verbindung getrennt")

func _on_peer_connected(id: int) -> void:
    if not multiplayer.is_server() or state["phase"] != "lobby":
        return
    var blue := 0
    var red := 0
    for p in state["players"].values():
        if p["team"] == "edge": blue += 1
        else: red += 1
    var team := "punk" if blue > red else "edge"
    state["players"][id] = _default_player(id, {}, team)
    _log("PEER #%d // Joined %s" % [id, team])
    _publish()

func _on_peer_disconnected(id: int) -> void:
    if not multiplayer.is_server():
        return
    if state["players"].has(id):
        if state["phase"] == "battle":
            var unit: Dictionary = state["players"][id]
            unit["alive"] = false
            unit["hp"] = 0
            state["players"][id] = unit
            if int(state["carrier"]) == id:
                state["carrier"] = 0
            _log("PEER #%d // Disconnected" % id)
            _check_victory()
            if state["phase"] == "battle" and int(state["active"]) == id:
                _advance_turn()
        else:
            state["players"].erase(id)
        _publish()

@rpc("any_peer", "reliable")
func send_profile(profile: Dictionary) -> void:
    if not multiplayer.is_server() or state["phase"] != "lobby":
        return
    var sender := multiplayer.get_remote_sender_id()
    if not state["players"].has(sender):
        return
    _set_profile(sender, profile)

func request_profile_update() -> void:
    if state["phase"] == "lobby" and multiplayer.is_server():
        _set_profile(1, my_profile)
    elif state["phase"] == "lobby" and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
        send_profile.rpc_id(1, my_profile)

func _set_profile(id: int, data: Dictionary) -> void:
    var p: Dictionary = state["players"][id]
    p["name"] = str(data.get("name", p["name"])).strip_edges().substr(0, 15)
    if p["name"].is_empty(): p["name"] = "GHOST"
    p["team"] = "punk" if str(data.get("team", p["team"])) == "punk" else "edge"
    p["class_id"] = GameRules.allowed_class(str(data.get("class_id", p["class_id"])))
    p["color_id"] = clampi(int(data.get("color_id", p["color_id"])), 0, 3)
    p["weapon"] = GameRules.allowed_weapon(str(data.get("weapon", p["weapon"])))
    state["players"][id] = p
    _publish()

func request_start() -> void:
    if multiplayer.is_server() and state["phase"] == "lobby":
        _begin_battle()

func _begin_battle() -> void:
    var blue := 0
    var red := 0
    for p in state["players"].values():
        if p["team"] == "edge": blue += 1
        else: red += 1
    if blue == 0 or red == 0:
        status.emit("MATCH BLOCKED // Beide Fraktionen benötigen Spieler")
        return
    if blue > BLUE_SPAWNS.size() or red > RED_SPAWNS.size():
        status.emit("MATCH BLOCKED // Maximal vier Spieler pro Team")
        return
    var blue_index := 0
    var red_index := 0
    var ids: Array = state["players"].keys()
    ids.sort()
    var order: Array = []
    for id in ids:
        var p: Dictionary = state["players"][id]
        p["hp"] = int(GameRules.class_for_unit(p)["health"])
        p["alive"] = true
        p["overwatch"] = false
        p["ap"] = 0
        if p["team"] == "edge":
            p["pos"] = BLUE_SPAWNS[blue_index]
            blue_index += 1
        else:
            p["pos"] = RED_SPAWNS[red_index]
            red_index += 1
        state["players"][id] = p
    # Alternating factions reduces first-turn advantage in team matches.
    var blue_ids: Array = []
    var red_ids: Array = []
    for id in ids:
        if state["players"][id]["team"] == "edge": blue_ids.append(id)
        else: red_ids.append(id)
    for i in range(maxi(blue_ids.size(), red_ids.size())):
        if i < blue_ids.size(): order.append(blue_ids[i])
        if i < red_ids.size(): order.append(red_ids[i])
    state["phase"] = "battle"
    state["round"] = 1
    state["winner"] = ""
    state["carrier"] = 0
    state["hostage"] = HOSTAGE_START
    state["turn_order"] = order
    state["turn_index"] = 0
    state["active"] = order[0]
    var starter: Dictionary = state["players"][order[0]]
    starter["ap"] = GameRules.AP_PER_TURN
    state["players"][order[0]] = starter
    _log("OPERATION STARTED // Rescue the hostage")
    _publish()
    _schedule_bot_if_needed()

func issue_action(action: String, cell: Vector2i = Vector2i.ZERO) -> void:
    if multiplayer.is_server():
        _server_command(local_id, action, cell)
    elif multiplayer.multiplayer_peer is ENetMultiplayerPeer:
        send_command.rpc_id(1, action, cell)

@rpc("any_peer", "reliable")
func send_command(action: String, cell: Vector2i) -> void:
    if multiplayer.is_server():
        _server_command(multiplayer.get_remote_sender_id(), action, cell)

func _server_command(sender: int, action: String, cell: Vector2i) -> void:
    if state["phase"] != "battle" or int(state["active"]) != sender:
        return
    if not state["players"].has(sender): return
    var unit: Dictionary = state["players"][sender]
    if not unit["alive"]: return
    var ap: int = unit["ap"]
    match action:
        "move":
            if ap < 1 or arena.is_blocked(cell): return
            var blocked := arena.walkable_blockers()
            for id in state["players"]:
                var other: Dictionary = state["players"][id]
                if id != sender and other["alive"]: blocked[other["pos"]] = true
            var distance := GameRules.walk_distance(unit["pos"], cell, blocked)
            if distance <= 0 or distance > int(GameRules.class_for_unit(unit)["movement"]): return
            var old_position: Vector2i = unit["pos"]
            unit["pos"] = cell
            unit["ap"] = ap - 1
            state["players"][sender] = unit
            if int(state["carrier"]) == sender:
                state["hostage"] = old_position
                if arena.is_extract(cell):
                    state["winner"] = "edge"
                    state["phase"] = "victory"
                    _log("EXTRACTION COMPLETE // EDGERUNNERS WIN")
            state["event"] = {"type": "move", "from": old_position, "to": cell, "actor": sender}
            _log("%s // Relocated" % unit["name"])
            if state["phase"] == "battle": _trigger_overwatch(sender)
        "fire":
            if ap < 2: return
            var target_id := _enemy_at(sender, cell)
            if target_id == 0: return
            if not _can_shoot(unit, cell): return
            unit["ap"] = ap - 2
            state["players"][sender] = unit
            _resolve_shot(sender, target_id, false)
        "overwatch":
            if ap < 1 or unit["overwatch"]: return
            unit["ap"] = ap - 1
            unit["overwatch"] = true
            state["players"][sender] = unit
            _log("%s // OVERWATCH ARMED" % unit["name"])
            state["event"] = {"type": "guard", "actor": sender}
        "interact":
            if ap < 1 or unit["team"] != "edge" or int(state["carrier"]) != 0: return
            if GameRules.range_between(unit["pos"], state["hostage"]) > 1: return
            unit["ap"] = ap - 1
            state["players"][sender] = unit
            state["carrier"] = sender
            _log("HOSTAGE SECURED // Reach green extraction zone")
            state["event"] = {"type": "rescue", "actor": sender}
        "end":
            _advance_turn()
        _:
            return
    _check_victory()
    _publish()

func _enemy_at(shooter_id: int, cell: Vector2i) -> int:
    var team: String = state["players"][shooter_id]["team"]
    for id in state["players"]:
        var p: Dictionary = state["players"][id]
        if p["alive"] and p["team"] != team and p["pos"] == cell: return int(id)
    return 0

func _can_shoot(unit: Dictionary, cell: Vector2i) -> bool:
    return GameRules.range_between(unit["pos"], cell) <= int(GameRules.weapon_for_unit(unit)["range"]) and GameRules.has_line_of_sight(unit["pos"], cell, arena.blockers)

func _resolve_shot(shooter_id: int, target_id: int, reaction: bool) -> void:
    var shooter: Dictionary = state["players"][shooter_id]
    var target: Dictionary = state["players"][target_id]
    var weapon: Dictionary = GameRules.weapon_for_unit(shooter)
    var hit_chance: int = int(weapon["accuracy"]) - (18 if _has_cover(target["pos"]) else 0) - (16 if reaction else 0)
    var hit := rng.randi_range(1, 100) <= hit_chance
    var damage: int = int(weapon["damage"]) / 2 if reaction else int(weapon["damage"])
    if hit:
        target["hp"] = maxi(0, int(target["hp"]) - damage)
        if target["hp"] == 0:
            target["alive"] = false
            if int(state["carrier"]) == target_id:
                state["hostage"] = target["pos"]
                state["carrier"] = 0
            _log("%s // Eliminated" % target["name"])
        else:
            _log("%s // HIT %d DMG" % [shooter["name"], damage])
    else:
        _log("%s // SHOT MISSED" % shooter["name"])
    state["players"][target_id] = target
    state["event"] = {"type": "fire", "from": shooter["pos"], "to": target["pos"], "hit": hit, "actor": shooter_id, "seq": int(state["event"].get("seq", 0)) + 1}

func _has_cover(cell: Vector2i) -> bool:
    for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
        if arena.blockers.has(cell + offset): return true
    return false

func _trigger_overwatch(mover_id: int) -> void:
    var mover: Dictionary = state["players"][mover_id]
    for id in state["players"]:
        var unit: Dictionary = state["players"][id]
        if not mover["alive"]: break
        if not unit["alive"] or not unit["overwatch"] or unit["team"] == mover["team"]: continue
        if not _can_shoot(unit, mover["pos"]): continue
        unit["overwatch"] = false
        state["players"][id] = unit
        _resolve_shot(int(id), mover_id, true)
        mover = state["players"][mover_id]

func _advance_turn() -> void:
    var order: Array = state["turn_order"]
    if order.is_empty(): return
    var current: int = int(state["active"])
    var old_unit: Dictionary = state["players"][current]
    old_unit["ap"] = 0
    state["players"][current] = old_unit
    for _step in range(order.size()):
        var index: int = (int(state["turn_index"]) + 1) % order.size()
        if index == 0:
            state["round"] = int(state["round"]) + 1
        state["turn_index"] = index
        var next_id: int = int(order[index])
        var next_unit: Dictionary = state["players"].get(next_id, {})
        if next_unit.is_empty() or not next_unit.get("alive", false): continue
        next_unit["ap"] = GameRules.AP_PER_TURN
        next_unit["overwatch"] = false
        state["players"][next_id] = next_unit
        state["active"] = next_id
        _log("ROUND %02d // %s'S TURN" % [int(state["round"]), next_unit["name"]])
        _check_victory()
        _schedule_bot_if_needed()
        return
    _check_victory()

func _check_victory() -> void:
    if state["phase"] != "battle": return
    var edge_alive := 0
    var punk_alive := 0
    for p in state["players"].values():
        if p["alive"]:
            if p["team"] == "edge": edge_alive += 1
            else: punk_alive += 1
    if edge_alive == 0 or int(state["round"]) > GameRules.MAX_ROUNDS:
        state["winner"] = "punk"
        state["phase"] = "victory"
        _log("CONTRACT FAILED // MAELSTROM WIN")
    elif punk_alive == 0:
        state["winner"] = "edge"
        state["phase"] = "victory"
        _log("BASE SECURED // EDGERUNNERS WIN")

func _log(line: String) -> void:
    state["log"].push_front(line)
    if state["log"].size() > 6: state["log"].resize(6)

func _publish() -> void:
    updated.emit()
    if multiplayer.is_server() and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
        receive_state.rpc(state)

@rpc("authority", "reliable")
func receive_state(snapshot: Dictionary) -> void:
    if multiplayer.is_server(): return
    state = snapshot
    if state["players"].has(local_id):
        my_profile["team"] = state["players"][local_id]["team"]
    updated.emit()

func _schedule_bot_if_needed() -> void:
    if state["phase"] == "battle" and not bot_working:
        var id: int = int(state["active"])
        if state["players"].has(id) and state["players"][id]["bot"]:
            bot_working = true
            call_deferred("_bot_turn")

func _bot_turn() -> void:
    await get_tree().create_timer(0.65).timeout
    if state["phase"] != "battle":
        bot_working = false
        return
    var id: int = int(state["active"])
    if not state["players"].has(id) or not state["players"][id]["bot"]:
        bot_working = false
        return
    var bot: Dictionary = state["players"][id]
    var enemy_ids: Array = []
    for other in state["players"]:
        var p: Dictionary = state["players"][other]
        if p["alive"] and p["team"] != bot["team"]: enemy_ids.append(other)
    enemy_ids.sort_custom(func(a, b): return GameRules.range_between(bot["pos"], state["players"][a]["pos"]) < GameRules.range_between(bot["pos"], state["players"][b]["pos"]))
    if not enemy_ids.is_empty():
        var enemy: Dictionary = state["players"][enemy_ids[0]]
        if _can_shoot(bot, enemy["pos"]):
            _server_command(id, "fire", enemy["pos"])
        else:
            var best: Vector2i = bot["pos"]
            var best_score: int = GameRules.range_between(best, enemy["pos"])
            var blocked := arena.walkable_blockers()
            for other in state["players"]:
                var p: Dictionary = state["players"][other]
                if p["alive"] and other != id: blocked[p["pos"]] = true
            for x in range(1, GameRules.WIDTH - 1):
                for y in range(1, GameRules.HEIGHT - 1):
                    var spot := Vector2i(x, y)
                    var score := GameRules.range_between(spot, enemy["pos"])
                    if score < best_score and GameRules.walk_distance(bot["pos"], spot, blocked) in range(1, int(GameRules.class_for_unit(bot)["movement"]) + 1):
                        best = spot
                        best_score = score
            if best != bot["pos"]:
                _server_command(id, "move", best)
    if state["phase"] == "battle" and int(state["active"]) == id:
        _server_command(id, "end", Vector2i.ZERO)
    bot_working = false
    _schedule_bot_if_needed()
