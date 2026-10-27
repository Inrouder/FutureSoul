extends Node2D

const INK := Color("0b101e")
const PANEL := Color("111c2c")
const PANEL2 := Color("18263a")
const CYAN := Color("48eedc")
const MAGENTA := Color("fa507b")
const GOLD := Color("e8b66b")
const WHITE := Color("e6eefa")
const MUTED := Color("8a9db3")
const WIDTH := 1440
const HEIGHT := 900

var arena: FutureArena
var match_game: MatchController
var ui_layer: CanvasLayer
var interface_root: Control
var status_text := "LOCAL SYSTEM READY"
var action_mode := "move"
var join_ip: LineEdit
var actors: Dictionary = {}
var hostage: Sprite2D
var previous_event := ""
var view_mode := "menu"

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    arena = FutureArena.new()
    arena.position = Vector2(38, 112)
    add_child(arena)
    arena.cell_clicked.connect(_on_cell_clicked)
    match_game = MatchController.new()
    match_game.arena = arena
    add_child(match_game)
    match_game.updated.connect(_on_updated)
    match_game.status.connect(_on_status)
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    interface_root = Control.new()
    interface_root.name = "FutureSoulUI"
    interface_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    interface_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(interface_root)
    _on_updated()

func _draw() -> void:
    draw_rect(Rect2(0, 0, WIDTH, HEIGHT), INK)
    for x in range(0, WIDTH, 32):
        draw_line(Vector2(x, 0), Vector2(x, HEIGHT), Color("223049", 0.16), 1)
    for y in range(0, HEIGHT, 32):
        draw_line(Vector2(0, y), Vector2(WIDTH, y), Color("223049", 0.16), 1)
    draw_rect(Rect2(0, 0, WIDTH, 7), CYAN)

func _panel(parent: Control, pos: Vector2, dimensions: Vector2, fill: Color = PANEL, trim: Color = CYAN) -> Panel:
    var p := Panel.new()
    p.position = pos
    p.size = dimensions
    p.mouse_filter = Control.MOUSE_FILTER_STOP
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = trim
    style.border_width_top = 1
    style.border_width_left = 1
    style.border_width_bottom = 2
    style.border_width_right = 2
    style.corner_radius_top_left = 2
    style.corner_radius_bottom_right = 2
    style.shadow_color = Color(0, 0, 0, 0.4)
    style.shadow_size = 8
    p.add_theme_stylebox_override("panel", style)
    parent.add_child(p)
    return p

func _label(parent: Control, value: String, pos: Vector2, dimensions: Vector2, size: int = 17, tint: Color = WHITE) -> Label:
    var label := Label.new()
    label.text = value
    label.position = pos
    label.size = dimensions
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", tint)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _button(parent: Control, label: String, pos: Vector2, dimensions: Vector2, callback: Callable, accent: Color = CYAN, filled: bool = false) -> Button:
    var btn := Button.new()
    btn.text = label
    btn.position = pos
    btn.size = dimensions
    btn.focus_mode = Control.FOCUS_NONE
    btn.add_theme_font_size_override("font_size", 16)
    btn.add_theme_color_override("font_color", INK if filled else WHITE)
    btn.add_theme_color_override("font_hover_color", INK)
    var normal := StyleBoxFlat.new()
    normal.bg_color = accent if filled else PANEL2
    normal.border_color = accent
    normal.border_width_bottom = 2
    normal.border_width_left = 1
    normal.border_width_right = 1
    var hover := normal.duplicate()
    hover.bg_color = accent
    var pressed := normal.duplicate()
    pressed.bg_color = accent.darkened(0.25)
    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", hover)
    btn.add_theme_stylebox_override("pressed", pressed)
    btn.pressed.connect(callback)
    parent.add_child(btn)
    return btn

func _text_input(parent: Control, current: String, pos: Vector2, dimensions: Vector2) -> LineEdit:
    var input := LineEdit.new()
    input.text = current
    input.position = pos
    input.size = dimensions
    input.max_length = 30
    input.add_theme_color_override("font_color", WHITE)
    input.add_theme_font_size_override("font_size", 17)
    var style := StyleBoxFlat.new()
    style.bg_color = INK
    style.border_color = Color("37546a")
    style.set_border_width_all(1)
    style.content_margin_left = 10
    input.add_theme_stylebox_override("normal", style)
    parent.add_child(input)
    return input

func _dropdown(parent: Control, names: Array, keys: Array, selected: Variant, pos: Vector2, on_change: Callable) -> void:
    var select := OptionButton.new()
    select.position = pos
    select.size = Vector2(363, 38)
    select.add_theme_font_size_override("font_size", 16)
    select.add_theme_color_override("font_color", WHITE)
    for i in range(names.size()):
        select.add_item(str(names[i]))
        if keys[i] == selected: select.select(i)
    select.item_selected.connect(func(index: int): on_change.call(keys[index]))
    parent.add_child(select)

func _clear_ui() -> void:
    for child in interface_root.get_children():
        interface_root.remove_child(child)
        child.queue_free()

func _on_status(message: String) -> void:
    status_text = message
    _rebuild_ui()

func _on_updated() -> void:
    if not is_instance_valid(interface_root): return
    _update_world()
    _rebuild_ui()

func _update_world() -> void:
    var state: Dictionary = match_game.state
    var showing: bool = state["phase"] in ["battle", "victory"]
    arena.visible = true
    arena.mode = str(state.get("mode", "kidnap"))
    arena.hacked = state.get("hacked", {"edge": [], "punk": []})
    for id in actors.keys():
        if not showing or not state["players"].has(id):
            var old: FutureActor = actors[id]
            old.queue_free()
            actors.erase(id)
    if showing:
        for id in state["players"]:
            var player: Dictionary = state["players"][id]
            if not actors.has(id):
                var actor := FutureActor.new()
                arena.actor_node.add_child(actor)
                actors[id] = actor
                actor.position = arena.cell_center(player["pos"])
            var sprite: FutureActor = actors[id]
            var info := player.duplicate()
            info["active"] = int(state["active"]) == int(id) and state["phase"] == "battle"
            info["carrying"] = int(state["carrier"]) == int(id)
            sprite.configure(info)
            var target: Vector2 = arena.cell_center(player["pos"])
            if sprite.position.distance_to(target) > 1:
                create_tween().tween_property(sprite, "position", target, 0.22).set_trans(Tween.TRANS_SINE)
        if not is_instance_valid(hostage):
            hostage = Sprite2D.new()
            hostage.texture = load("res://assets/tiles/hostage.png")
            hostage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            arena.actor_node.add_child(hostage)
        hostage.position = arena.cell_center(state["hostage"])
        hostage.visible = state["mode"] == "kidnap" and int(state["carrier"]) == 0
        var event_text: String = str(state["event"])
        if event_text != previous_event:
            previous_event = event_text
            _play_event(state["event"])
    elif is_instance_valid(hostage):
        hostage.queue_free()
        hostage = null
    arena.queue_redraw()

func _play_event(event: Dictionary) -> void:
    if not event.get("type", "") in ["fire", "portal", "hack"]: return
    var tracer := Line2D.new()
    tracer.width = 3.0
    tracer.default_color = GOLD if event.get("type") == "hack" else (Color("af7dff") if event.get("type") == "portal" else (CYAN if event.get("hit", false) else MAGENTA))
    var from_cell: Vector2i = event.get("from", event.get("to", Vector2i.ZERO))
    tracer.points = PackedVector2Array([arena.cell_center(from_cell), arena.cell_center(event["to"])])
    tracer.antialiased = false
    arena.add_child(tracer)
    var tween := create_tween()
    tween.tween_property(tracer, "modulate:a", 0.0, 0.3)
    tween.tween_callback(tracer.queue_free)

func _rebuild_ui() -> void:
    if not is_instance_valid(interface_root): return
    _clear_ui()
    match str(match_game.state["phase"]):
        "menu", "connecting": _show_menu()
        "lobby": _show_lobby()
        "battle", "victory": _show_battle()
    _label(interface_root, "BUILD 0.2.0  //  FUTURESOUL PROTOCOL", Vector2(40, 861), Vector2(620, 26), 12, MUTED)
    _label(interface_root, status_text, Vector2(735, 861), Vector2(660, 26), 12, CYAN)

func _sprite_role(profile: Dictionary) -> String:
    var role := str(profile.get("class_id", "e_runner"))
    if profile.get("faction", "") == "maelstrom": return "punk"
    if role in ["m_gunner", "e_big", "k_rocky", "heavy"]: return "heavy"
    if role in ["e_runner", "k_raven", "netrunner"]: return "netrunner"
    return "runner"

func _choose_mode(value: String) -> void:
    match_game.selected_mode = GameRules.valid_mode(value)
    if value == "kidnap" and match_game.my_profile["faction"] == "maelstrom":
        match_game.my_profile["faction"] = "edgerunner"
        match_game.my_profile["class_id"] = "e_runner"
        match_game.my_profile["weapon"] = "wire"
    _rebuild_ui()

func _show_menu() -> void:
    var shade := ColorRect.new()
    shade.color = Color("060a14", 0.88)
    shade.size = Vector2(WIDTH, HEIGHT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    interface_root.add_child(shade)
    var p := _panel(interface_root, Vector2(145, 76), Vector2(1150, 746), PANEL, CYAN)
    _label(p, "F U T U R E  /  S O U L", Vector2(37, 26), Vector2(1080, 70), 45, CYAN)
    _label(p, "TACTICAL CYBERPUNK // TURN-BASED PVP // BLACKGRID NETWORK", Vector2(40, 101), Vector2(1030, 30), 17, GOLD)
    var vertical := ColorRect.new()
    vertical.color = Color("365367")
    vertical.position = Vector2(570, 161)
    vertical.size = Vector2(2, 539)
    p.add_child(vertical)
    _label(p, "01 // OPERATION", Vector2(39, 159), Vector2(490, 29), 19, CYAN)
    _dropdown(p, ["01  MAELSTROM KIDNAP", "02  BASE VS BASE", "03  HACK THE BASE"], ["kidnap", "skirmish", "hack"], match_game.selected_mode, Vector2(39, 199), func(v): _choose_mode(str(v)))
    var mission_text := ""
    match match_game.selected_mode:
        "kidnap":
            mission_text = "Geiselbefreiung: Edgerunner oder Dragon Clan\ngegen Maelstrom-Verteidiger. Schütze den NPC\nund erreiche die leuchtende Extraktionszone."
        "skirmish":
            mission_text = "Zwei Stützpunkte, zwei Squads. Taktische\nDeckung, Spezialfähigkeiten und wechselnde\nZüge. Schalte die gegnerische Fraktion aus."
        "hack":
            mission_text = "Infiltriere die feindliche Basis. Extrahiere\nzwei verschlüsselte Zugangscodes und knacke\nanschließend den zentralen Hauptrechner."
    _label(p, mission_text, Vector2(40, 263), Vector2(500, 116), 18, WHITE)
    _label(p, "QUICK START  /  CPU OPPONENTS", Vector2(40, 396), Vector2(500, 29), 15, GOLD)
    _button(p, "SOLO-TRAINING STARTEN", Vector2(39, 432), Vector2(490, 58), func(): match_game.start_training(), CYAN, true)
    _label(p, "LAN MULTIPLAYER   //   UDP 7777", Vector2(40, 510), Vector2(485, 29), 15, GOLD)
    _button(p, "HOST ERSTELLEN", Vector2(39, 545), Vector2(218, 54), func(): match_game.start_host(), CYAN)
    join_ip = _input(p, "127.0.0.1", Vector2(271, 548), Vector2(168, 48))
    _button(p, "JOIN", Vector2(447, 545), Vector2(82, 54), func(): match_game.start_join(join_ip.text), GOLD)
    _label(p, "LAN: IP-Adresse des Hosts eingeben. Für Internet\nVPN oder UDP-Portweiterleitung erforderlich.", Vector2(41, 624), Vector2(491, 66), 14, MUTED)
    _label(p, "02 // OPERATIVE DESIGNER", Vector2(604, 159), Vector2(500, 29), 19, CYAN)
    var preview := _panel(p, Vector2(970, 203), Vector2(164, 167), Color("0b1826"), MAGENTA)
    var avatar := TextureRect.new()
    avatar.texture = load("res://assets/units/%s_%d.png" % [_sprite_role(match_game.my_profile), match_game.my_profile["color_id"]])
    avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    avatar.position = Vector2(28, 20)
    avatar.size = Vector2(112, 126)
    preview.add_child(avatar)
    _label(p, "CODENAME", Vector2(604, 204), Vector2(300, 26), 14, MUTED)
    var nick := _input(p, str(match_game.my_profile["name"]), Vector2(604, 236), Vector2(290, 44))
    nick.text_submitted.connect(func(v: String): _update_profile("name", v))
    nick.focus_exited.connect(func(): _update_profile("name", nick.text))
    _label(p, "FRAKTION", Vector2(604, 296), Vector2(312, 24), 14, MUTED)
    var factions: Array = ["edgerunner", "kobantec"] if match_game.selected_mode == "kidnap" else ["maelstrom", "edgerunner", "kobantec"]
    var faction_names: Array = []
    for faction in factions: faction_names.append(GameRules.FACTIONS[faction])
    _dropdown(p, faction_names, factions, match_game.my_profile["faction"], Vector2(604, 326), func(v): _update_profile("faction", v))
    _label(p, "SPEZIALKLASSE", Vector2(604, 391), Vector2(322, 25), 14, MUTED)
    var class_keys: Array = GameRules.classes_for_faction(str(match_game.my_profile["faction"]))
    var class_names: Array = []
    for k in class_keys: class_names.append(GameRules.CLASSES[k]["label"])
    _dropdown(p, class_names, class_keys, match_game.my_profile["class_id"], Vector2(604, 420), func(v): _update_profile("class_id", v))
    _label(p, "ARMOR TINT", Vector2(604, 484), Vector2(300, 23), 14, MUTED)
    _dropdown(p, ["NEON CYAN", "ULTRA VIOLET", "SUNSET GOLD", "MALWARE RED"], [0, 1, 2, 3], match_game.my_profile["color_id"], Vector2(604, 514), func(v): _update_profile("color_id", v))
    var loadout: Dictionary = GameRules.CLASSES[match_game.my_profile["class_id"]]
    _label(p, "AUSRUESTUNG / WEAPON", Vector2(604, 575), Vector2(514, 28), 14, GOLD)
    var equipment: Array = GameRules.equipment_for_class(str(match_game.my_profile["class_id"]))
    var weapon_names: Array = []
    for weapon_id in equipment: weapon_names.append(GameRules.WEAPONS[weapon_id]["label"])
    _dropdown(p, weapon_names, equipment, match_game.my_profile["weapon"], Vector2(604, 606), func(v): _update_profile("weapon", v))
    _label(p, "CYBERWARE // " + str(loadout["skill"]), Vector2(604, 663), Vector2(514, 28), 16, CYAN)
    _label(p, "Jede Klasse besitzt passende Waffen-Loadouts.\\nWeitere Ruestungs- und Outfit-Slots folgen.", Vector2(604, 694), Vector2(514, 46), 13, MUTED)
    if match_game.state["phase"] == "connecting":
        _label(p, "VERBINDUNG WIRD AUFGEBAUT ...", Vector2(42, 702), Vector2(530, 30), 16, GOLD)

func _show_lobby() -> void:
    var mode := str(match_game.state["mode"])
    _header("LOBBY // OPERATIVE CONFIGURATION", GameRules.MODES[mode] + "  /  AWAITING SQUADS")
    var p := _panel(interface_root, Vector2(38, 112), Vector2(553, 707), PANEL)
    _label(p, "01 // CHARACTER DESIGNER", Vector2(23, 20), Vector2(505, 42), 23, CYAN)
    var avatar := TextureRect.new()
    avatar.texture = load("res://assets/units/%s_%d.png" % [_sprite_role(match_game.my_profile), match_game.my_profile["color_id"]])
    avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    avatar.position = Vector2(385, 71)
    avatar.size = Vector2(125, 135)
    p.add_child(avatar)
    _label(p, "CODENAME", Vector2(24, 74), Vector2(335, 25), 13, MUTED)
    var nick := _input(p, str(match_game.my_profile["name"]), Vector2(23, 107), Vector2(335, 44))
    nick.text_submitted.connect(func(v: String): _update_profile("name", v))
    nick.focus_exited.connect(func(): _update_profile("name", nick.text))
    _label(p, "TEAM / EINSATZSEITE", Vector2(23, 182), Vector2(365, 23), 13, MUTED)
    _dropdown(p, ["BLUE // INFILTRATION", "RED // DEFENSE"], ["edge", "punk"], match_game.my_profile["team"], Vector2(23, 209), func(v): _update_profile("team", v))
    _label(p, "FRAKTION", Vector2(23, 268), Vector2(310, 24), 13, MUTED)
    var factions: Array = ["maelstrom", "edgerunner", "kobantec"]
    if mode == "kidnap":
        factions = ["maelstrom"] if match_game.my_profile["team"] == "punk" else ["edgerunner", "kobantec"]
    var names: Array = []
    for f_id in factions: names.append(GameRules.FACTIONS[f_id])
    _dropdown(p, names, factions, match_game.my_profile["faction"], Vector2(23, 295), func(v): _update_profile("faction", v))
    _label(p, "KLASSE / CYBERWARE", Vector2(23, 354), Vector2(335, 24), 13, MUTED)
    var ids: Array = GameRules.classes_for_faction(str(match_game.my_profile["faction"]))
    var class_names: Array = []
    for role in ids: class_names.append(GameRules.CLASSES[role]["label"])
    _dropdown(p, class_names, ids, match_game.my_profile["class_id"], Vector2(23, 382), func(v): _update_profile("class_id", v))
    _label(p, "ARMOR COLOR", Vector2(23, 441), Vector2(325, 25), 13, MUTED)
    _dropdown(p, ["NEON CYAN", "ULTRA VIOLET", "SUNSET GOLD", "MALWARE RED"], [0, 1, 2, 3], match_game.my_profile["color_id"], Vector2(23, 469), func(v): _update_profile("color_id", v))
    var loadout: Dictionary = GameRules.CLASSES[str(match_game.my_profile["class_id"])]
    _label(p, "AUSRUESTUNG / WERKZEUG", Vector2(23, 521), Vector2(515, 28), 14, GOLD)
    var equipment: Array = GameRules.equipment_for_class(str(match_game.my_profile["class_id"]))
    var equipment_names: Array = []
    for weapon_id in equipment: equipment_names.append(GameRules.WEAPONS[weapon_id]["label"])
    _dropdown(p, equipment_names, equipment, match_game.my_profile["weapon"], Vector2(23, 553), func(v): _update_profile("weapon", v))
    _label(p, "SKILL  // " + str(loadout["skill"]), Vector2(23, 615), Vector2(515, 27), 16, CYAN)
    _label(p, "Host prueft Ausruestung, Klassen und Aktionen.\\nBots sind im Solo-Training verfuegbar.", Vector2(23, 656), Vector2(515, 45), 14, MUTED)
    var roster := _panel(interface_root, Vector2(609, 112), Vector2(794, 707), PANEL, MAGENTA)
    _label(roster, "02 // MATCH ROSTER", Vector2(24, 20), Vector2(720, 44), 24, MAGENTA)
    _label(roster, "CODENAME        SIDE        FACTION / CLASS", Vector2(25, 77), Vector2(743, 23), 14, MUTED)
    var index := 0
    for id in match_game.state["players"]:
        var member: Dictionary = match_game.state["players"][id]
        var tint := CYAN if member["team"] == "edge" else MAGENTA
        _label(roster, "%s   /   %s   /   %s  •  %s" % [member["name"], "BLUE" if member["team"] == "edge" else "RED", GameRules.FACTIONS[member["faction"]], GameRules.CLASSES[member["class_id"]]["label"]], Vector2(26, 120 + index * 45), Vector2(735, 38), 16, tint)
        index += 1
    _label(roster, "Jede Seite benötigt mindestens einen Operator.\nHost validiert Bewegung, Schaden, Skills und Hacks.", Vector2(26, 513), Vector2(735, 70), 17, MUTED)
    if match_game.multiplayer.is_server():
        _button(roster, "MISSION STARTEN  //  " + GameRules.MODES[mode], Vector2(23, 594), Vector2(744, 61), func(): match_game.request_start(), CYAN, true)
    else:
        _label(roster, "WARTE AUF DEN HOST ...", Vector2(27, 609), Vector2(720, 41), 23, GOLD)
    _button(interface_root, "ZURÜCK", Vector2(1235, 36), Vector2(167, 49), func(): _leave_match(), MAGENTA)

func _header(title: String, subtitle: String) -> void:
    var head := _panel(interface_root, Vector2(36, 22), Vector2(1368, 70), PANEL, CYAN)
    _label(head, "F/S", Vector2(19, 14), Vector2(75, 42), 28, CYAN)
    _label(head, title, Vector2(98, 12), Vector2(728, 30), 25, WHITE)
    _label(head, subtitle, Vector2(102, 43), Vector2(745, 23), 13, MUTED)

func _show_battle() -> void:
    var state: Dictionary = match_game.state
    var mode := str(state["mode"])
    _header(GameRules.MODES[mode] + "  /  BLACKGRID", "TURN-BASED PVP // CHOOSE YOUR MOVE // EXECUTE")
    var side := _panel(interface_root, Vector2(958, 112), Vector2(446, 608), PANEL, CYAN)
    _label(side, "OPERATION // %s" % mode.to_upper(), Vector2(18, 17), Vector2(407, 25), 15, GOLD)
    _label(side, GameRules.MODES[mode], Vector2(18, 49), Vector2(417, 38), 25, WHITE)
    var objective := ""
    match mode:
        "kidnap":
            objective = "BLUE: Geisel befreien & evakuieren.\nRED: Rettung 12 Runden verhindern."
        "skirmish":
            objective = "Zwei Basen / zwei Squads. Eliminiere\ndie feindliche Einsatzgruppe."
        "hack":
            var mine_id: int = match_game.local_id
            var side_key := "edge"
            if state["players"].has(mine_id): side_key = state["players"][mine_id]["team"]
            var hacked: Array = state["hacked"][side_key]
            objective = "CODES %d/2  //  CORE %s\nFeindbasis: 2 Keys, dann Mainframe." % [mini(hacked.size(), 2), "OPEN" if hacked.has(2) else "LOCKED"]
    _label(side, objective, Vector2(18, 91), Vector2(407, 64), 16, MUTED)
    _label(side, "ROUND %02d / %02d" % [int(state["round"]), GameRules.MAX_ROUNDS], Vector2(18, 158), Vector2(360, 30), 20, GOLD)
    var active: int = int(state["active"])
    if state["players"].has(active):
        var current: Dictionary = state["players"][active]
        var tint := CYAN if current["team"] == "edge" else MAGENTA
        _label(side, "ACTIVE // " + current["name"], Vector2(18, 194), Vector2(411, 30), 19, tint)
        _label(side, "AP %d  /  HP %d  /  %s" % [int(current["ap"]), int(current["hp"]), str(current["class_id"]).to_upper()], Vector2(18, 226), Vector2(410, 27), 15, WHITE)
    var mine: Dictionary = state["players"].get(match_game.local_id, {})
    if not mine.is_empty():
        _label(side, "YOUR CYBERWARE // " + str(GameRules.CLASSES[mine["class_id"]]["skill"]), Vector2(18, 262), Vector2(409, 28), 15, CYAN)
    var your_turn := state["phase"] == "battle" and active == match_game.local_id and not mine.is_empty() and mine["alive"]
    _label(side, "COMMANDS // %s" % ["YOUR TURN" if your_turn else "STANDBY"], Vector2(18, 298), Vector2(411, 26), 16, GOLD)
    var buttons: Array = [
        ["1 / MOVE", "move", CYAN], ["2 / FIRE", "fire", MAGENTA],
        ["3 / CYBERWARE", "skill", GOLD], ["4 / OVERWATCH", "overwatch", CYAN],
    ]
    if mode == "kidnap":
        buttons.append(["5 / HOSTAGE", "interact", GOLD])
    elif mode == "hack":
        buttons.append(["5 / BREACH CODE", "hack", GOLD])
    if mine.get("class_id", "") == "k_raven":
        buttons.append(["6 / WALL PORTAL", "portal", Color("a894ff")])
    for i in range(buttons.size()):
        var item: Array = buttons[i]
        var px := 18 + (i % 2) * 211
        var py := 331 + int(i / 2) * 54
        var action_key := str(item[1])
        var button := _button(side, str(item[0]), Vector2(px, py), Vector2(199, 44), func(): _action_pressed(action_key), item[2], action_key == action_mode)
        button.disabled = not your_turn
    var end_btn := _button(side, "END TURN  [SPACE]", Vector2(18, 506), Vector2(411, 46), func(): match_game.issue_action("end"), GOLD)
    end_btn.disabled = not your_turn
    _label(side, "LINK: %s / PEER %d" % ["ONLINE" if match_game.multiplayer.multiplayer_peer is ENetMultiplayerPeer else "LOCAL", match_game.local_id], Vector2(20, 564), Vector2(411, 27), 13, MUTED)
    var bottom := _panel(interface_root, Vector2(38, 737), Vector2(1366, 98), PANEL, GOLD)
    _label(bottom, "FIELD LOG //", Vector2(18, 13), Vector2(220, 25), 14, GOLD)
    var lines: Array = state["log"]
    _label(bottom, str(lines[0]) if not lines.is_empty() else "--", Vector2(18, 42), Vector2(790, 33), 18, WHITE)
    _label(bottom, "CLICK: TARGET  /  [1-6] ACTION  /  [SPACE] END TURN", Vector2(790, 44), Vector2(553, 30), 13, MUTED)
    if state["phase"] == "victory":
        var winner: String = str(state["winner"])
        var tint := GOLD if winner == "draw" else (CYAN if winner == "edge" else MAGENTA)
        var over := _panel(interface_root, Vector2(300, 240), Vector2(795, 341), Color("0d1424"), tint)
        _label(over, "CONTRACT CLOSED", Vector2(38, 38), Vector2(736, 43), 32, tint)
        _label(over, "DRAW // STALEMATE" if winner == "draw" else ("BLUE SQUAD VICTORY" if winner == "edge" else "RED SQUAD VICTORY"), Vector2(38, 114), Vector2(733, 54), 35, WHITE)
        _label(over, "Alle Operatoren haben das finale Ergebnis erhalten.", Vector2(39, 183), Vector2(717, 36), 17, MUTED)
        _button(over, "ZURÜCK ZUM HAUPTMENÜ", Vector2(40, 250), Vector2(715, 57), func(): _leave_match(), tint, true)

func _leave_match() -> void:
    match_game._disconnect_peer()
    match_game.reset_state()
    action_mode = "move"
    previous_event = ""
    status_text = "LOCAL SYSTEM READY"

func _update_profile(key: String, value: Variant) -> void:
    match_game.my_profile[key] = value
    if key == "name" and str(value).strip_edges().is_empty():
        match_game.my_profile[key] = "GHOST"
    if key in ["faction", "team"]:
        if match_game.selected_mode == "kidnap":
            if match_game.my_profile["team"] == "punk":
                match_game.my_profile["faction"] = "maelstrom"
            elif match_game.my_profile["faction"] == "maelstrom":
                match_game.my_profile["faction"] = "edgerunner"
        var ids: Array = GameRules.classes_for_faction(str(match_game.my_profile["faction"]))
        if not ids.has(match_game.my_profile["class_id"]):
            match_game.my_profile["class_id"] = ids[0]
    if key in ["class_id", "faction", "team"]:
        match_game.my_profile["weapon"] = GameRules.CLASSES[str(match_game.my_profile["class_id"])]["weapon"]
    match_game.request_profile_update()
    _rebuild_ui()

func _action_pressed(value: String) -> void:
    if value in ["interact", "overwatch"]:
        match_game.issue_action(value)
        return
    if value == "skill":
        var mine: Dictionary = match_game.state["players"].get(match_game.local_id, {})
        if mine.get("class_id", "") in ["e_psycho", "k_first", "k_rocky", "runner"]:
            match_game.issue_action("skill")
            return
    action_mode = value
    status_text = "TARGETING // %s - Select map tile" % value.to_upper()
    _rebuild_ui()

func _on_cell_clicked(cell: Vector2i) -> void:
    if match_game.state["phase"] != "battle": return
    if int(match_game.state["active"]) != match_game.local_id: return
    if action_mode == "hack":
        _open_breach(cell)
    elif action_mode in ["move", "fire", "skill", "portal"]:
        match_game.issue_action(action_mode, cell)

func _open_breach(cell: Vector2i) -> void:
    if match_game.state["mode"] != "hack": return
    var me: Dictionary = match_game.state["players"].get(match_game.local_id, {})
    if me.is_empty(): return
    var opp := "punk" if me["team"] == "edge" else "edge"
    var index: int = match_game.TERMINALS[opp].find(cell)
    if index < 0:
        status_text = "ACCESS DENIED // Select enemy terminal"
        _rebuild_ui()
        return
    var progress: Array = match_game.state["hacked"][me["team"]]
    if progress.has(index) or (index == 2 and (not progress.has(0) or not progress.has(1))):
        status_text = "LOCKED // Collect both keys before mainframe"
        _rebuild_ui()
        return
    var cost := 1 if me["class_id"] in ["e_runner", "k_raven"] else 2
    if GameRules.range_between(me["pos"], cell) > 1 or int(me["ap"]) < cost:
        status_text = "ACCESS DENIED // Reach terminal and reserve %d AP" % cost
        _rebuild_ui()
        return
    var popup := CodeBreach.new()
    popup.initialize(index, cell)
    popup.completed.connect(func(proof: Array, target: Vector2i):
        if is_instance_valid(popup): popup.queue_free()
        match_game.issue_action("breach|" + JSON.stringify(proof), target)
    )
    popup.dismissed.connect(func():
        if is_instance_valid(popup): popup.queue_free()
    )
    interface_root.add_child(popup)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    if match_game.state["phase"] != "battle": return
    if event.keycode == KEY_SPACE:
        match_game.issue_action("end")
    elif event.keycode == KEY_1: _action_pressed("move")
    elif event.keycode == KEY_2: _action_pressed("fire")
    elif event.keycode == KEY_3: _action_pressed("skill")
    elif event.keycode == KEY_4: _action_pressed("overwatch")
    elif event.keycode == KEY_5: _action_pressed("hack" if match_game.state["mode"] == "hack" else "interact")
    elif event.keycode == KEY_6: _action_pressed("portal")
