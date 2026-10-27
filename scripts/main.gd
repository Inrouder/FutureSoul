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
        hostage.visible = int(state["carrier"]) == 0
        var event_text: String = str(state["event"])
        if event_text != previous_event:
            previous_event = event_text
            _play_event(state["event"])
    elif is_instance_valid(hostage):
        hostage.queue_free()
        hostage = null
    arena.queue_redraw()

func _play_event(event: Dictionary) -> void:
    if event.get("type", "") != "fire": return
    var tracer := Line2D.new()
    tracer.width = 3.0
    tracer.default_color = CYAN if event.get("hit", false) else MAGENTA
    tracer.points = PackedVector2Array([arena.cell_center(event["from"]), arena.cell_center(event["to"])])
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
    _label(interface_root, "BUILD 0.1.0  //  FUTURESOUL PROTOCOL", Vector2(40, 861), Vector2(620, 26), 12, MUTED)
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
    var preview := _panel(p, Vector2(934, 203), Vector2(164, 167), Color("0b1826"), MAGENTA)
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
    _label(p, "LOADOUT // " + str(GameRules.WEAPONS[loadout["weapon"]]["label"]), Vector2(604, 584), Vector2(514, 28), 17, GOLD)
    _label(p, "CYBERWARE // " + str(loadout["skill"]), Vector2(604, 615), Vector2(514, 28), 16, CYAN)
    _label(p, "KLASSENWAFFEN SIND BALANCIERT FEST ZUGEWIESEN.\nINDIVIDUELLE OUTFITS UND AUSRÜSTUNGSSLOTS FOLGEN.", Vector2(604, 660), Vector2(514, 56), 13, MUTED)
    if match_game.state["phase"] == "connecting":
        _label(p, "VERBINDUNG WIRD AUFGEBAUT ...", Vector2(42, 702), Vector2(530, 30), 16, GOLD)

func _show_lobby() -> void:
    _header("LOBBY // OPERATOR CONFIGURATION", "MAELSTROM KIDNAP  /  WAITING FOR SQUADS")
    var p := _panel(interface_root, Vector2(38, 112), Vector2(553, 707), PANEL)
    _label(p, "01 // CHARAKTER-EDITOR", Vector2(23, 20), Vector2(505, 42), 24, CYAN)
    var avatar := TextureRect.new()
    avatar.texture = load("res://assets/units/%s_%d.png" % ["punk" if match_game.my_profile["team"] == "punk" else match_game.my_profile["class_id"], match_game.my_profile["color_id"]])
    avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    avatar.position = Vector2(377, 75)
    avatar.size = Vector2(139, 143)
    p.add_child(avatar)
    _label(p, "CODENAME", Vector2(24, 79), Vector2(335, 25), 13, MUTED)
    var name_line := _text_input(p, match_game.my_profile["name"], Vector2(23, 113), Vector2(320, 44))
    name_line.text_submitted.connect(func(value: String): _update_profile("name", value))
    name_line.focus_exited.connect(func(): _update_profile("name", name_line.text))
    _label(p, "FRAKTION", Vector2(23, 232), Vector2(330, 24), 13, MUTED)
    _dropdown(p, ["EDGERUNNERS / INFILTRATION", "MAELSTROM / DEFENSE"], ["edge", "punk"], match_game.my_profile["team"], Vector2(23, 260), func(v): _update_profile("team", v))
    _label(p, "KLASSE", Vector2(23, 319), Vector2(320, 23), 13, MUTED)
    _dropdown(p, ["STREET RUNNER / 5 FELDER", "NETRUNNER / 4 FELDER", "ENFORCER / 3 FELDER"], ["runner", "netrunner", "heavy"], match_game.my_profile["class_id"], Vector2(23, 348), func(v): _update_profile("class_id", v))
    _label(p, "RÜSTUNGSFARBE", Vector2(23, 407), Vector2(320, 23), 13, MUTED)
    _dropdown(p, ["NEON CYAN", "ULTRA VIOLET", "SUNSET GOLD", "MALWARE RED"], [0,1,2,3], match_game.my_profile["color_id"], Vector2(23, 435), func(v): _update_profile("color_id", v))
    _label(p, "STARTWAFFE", Vector2(23, 496), Vector2(320, 23), 13, MUTED)
    _dropdown(p, ["MANTIS AR / RIFLE", "NEON-9 / PISTOL", "STATIC / SMG"], ["rifle", "pistol", "smg"], match_game.my_profile["weapon"], Vector2(23, 525), func(v): _update_profile("weapon", v))
    _label(p, "Die Auswahl wird an den Match-Host übertragen.", Vector2(23, 593), Vector2(505, 40), 14, MUTED)
    var roster := _panel(interface_root, Vector2(609, 112), Vector2(794, 707), PANEL, MAGENTA)
    _label(roster, "02 // MATCH-ROSTER", Vector2(24, 20), Vector2(720, 44), 24, MAGENTA)
    _label(roster, "CODENAME                 FACTION                  CLASS", Vector2(25, 83), Vector2(730, 23), 14, MUTED)
    var index := 0
    for id in match_game.state["players"]:
        var member: Dictionary = match_game.state["players"][id]
        var c := CYAN if member["team"] == "edge" else MAGENTA
        _label(roster, "%s    /    %s    /    %s" % [member["name"], "EDGERUNNER" if member["team"] == "edge" else "MAELSTROM", str(member["class_id"]).to_upper()], Vector2(26, 119 + index * 46), Vector2(741, 40), 18, c)
        index += 1
    _label(roster, "PvP: Mindestens 1 Spieler je Fraktion. Der Host startet\ndas Match. Für einen ersten Test: Solo-Training im Menü.", Vector2(26, 517), Vector2(735, 64), 17, MUTED)
    if match_game.multiplayer.is_server():
        _button(roster, "MISSION STARTEN", Vector2(23, 599), Vector2(744, 61), func(): match_game.request_start(), CYAN, true)
    else:
        _label(roster, "WARTE AUF DEN HOST ...", Vector2(27, 613), Vector2(720, 41), 23, GOLD)
    _button(interface_root, "ZURÜCK", Vector2(1235, 36), Vector2(167, 49), func(): _leave_match(), MAGENTA)

func _header(title: String, subtitle: String) -> void:
    var head := _panel(interface_root, Vector2(36, 22), Vector2(1368, 70), PANEL, CYAN)
    _label(head, "F/S", Vector2(19, 14), Vector2(75, 42), 28, CYAN)
    _label(head, title, Vector2(98, 12), Vector2(728, 30), 25, WHITE)
    _label(head, subtitle, Vector2(102, 43), Vector2(745, 23), 13, MUTED)

func _show_battle() -> void:
    var state: Dictionary = match_game.state
    _header("MAELSTROM KIDNAP  /  BLACKGRID", "EXTRACTION CONTRACT    //    TURN-BASED TACTICAL SHOOTER")
    var side := _panel(interface_root, Vector2(958, 112), Vector2(446, 608), PANEL, CYAN)
    _label(side, "MISSION // 001", Vector2(18, 18), Vector2(410, 25), 16, GOLD)
    _label(side, "GEISELRETTUNG", Vector2(18, 51), Vector2(400, 38), 26, WHITE)
    _label(side, "EDGERUNNERS: Geisel holen, zur\ngrünen Zone bringen.\nMAELSTROM: 12 Runden abwehren.", Vector2(18, 96), Vector2(408, 89), 17, MUTED)
    _label(side, "ROUND %02d / 12" % int(state["round"]), Vector2(18, 181), Vector2(360, 32), 21, GOLD)
    var active: int = int(state["active"])
    if state["players"].has(active):
        var current: Dictionary = state["players"][active]
        var tint := CYAN if current["team"] == "edge" else MAGENTA
        _label(side, "ACTIVE // " + current["name"], Vector2(18, 221), Vector2(416, 30), 21, tint)
        _label(side, "AP: %d  |  HP: %d  |  %s" % [int(current["ap"]), int(current["hp"]), str(current["weapon"]).to_upper()], Vector2(18, 256), Vector2(400, 27), 17, WHITE)
    var mine: Dictionary = state["players"].get(match_game.local_id, {})
    if not mine.is_empty():
        _label(side, "YOU // %s / HP %d" % [mine["name"], int(mine["hp"])], Vector2(18, 292), Vector2(410, 27), 17, CYAN if mine["team"] == "edge" else MAGENTA)
    var your_turn: bool = state["phase"] == "battle" and active == match_game.local_id and not mine.is_empty() and mine["alive"]
    _label(side, "ACTIONS // %s" % ["YOUR TURN" if your_turn else "WAITING"], Vector2(18, 333), Vector2(410, 28), 17, GOLD)
    var buttons := [
        ["1 / BEWEGEN", "move", CYAN], ["2 / SCHIESSEN", "fire", MAGENTA],
        ["3 / GEISEL", "interact", GOLD], ["4 / OVERWATCH", "overwatch", CYAN],
    ]
    for i in range(buttons.size()):
        var item: Array = buttons[i]
        var px := 18 + (i % 2) * 211
        var py := 373 + (i / 2) * 57
        var b := _button(side, item[0], Vector2(px, py), Vector2(199, 46), func(): _action_pressed(item[1]), item[2], item[1] == action_mode)
        b.disabled = not your_turn
    var end_btn := _button(side, "ZUG BEENDEN  [SPACE]", Vector2(18, 495), Vector2(411, 46), func(): match_game.issue_action("end"), GOLD)
    end_btn.disabled = not your_turn
    _label(side, "LINK: %s  |  UNIT #%d" % ["ONLINE" if match_game.multiplayer.multiplayer_peer is ENetMultiplayerPeer else "OFFLINE", match_game.local_id], Vector2(20, 560), Vector2(410, 29), 13, MUTED)
    var bottom := _panel(interface_root, Vector2(38, 737), Vector2(1366, 98), PANEL, GOLD)
    _label(bottom, "FIELD LOG //", Vector2(18, 13), Vector2(225, 25), 14, GOLD)
    var lines: Array = state["log"]
    _label(bottom, str(lines[0]) if not lines.is_empty() else "--", Vector2(18, 43), Vector2(790, 34), 19, WHITE)
    _label(bottom, "[LINKSKLICK] ZIELFELD    [1-4] AKTION    [SPACE] ZUG BEENDEN", Vector2(807, 44), Vector2(540, 34), 13, MUTED)
    if state["phase"] == "victory":
        var tint := CYAN if state["winner"] == "edge" else MAGENTA
        var over := _panel(interface_root, Vector2(300, 240), Vector2(795, 341), Color("0d1424"), tint)
        _label(over, "CONTRACT CLOSED", Vector2(38, 38), Vector2(736, 43), 32, tint)
        _label(over, "EDGERUNNERS WIN" if state["winner"] == "edge" else "MAELSTROM WIN", Vector2(38, 114), Vector2(733, 54), 36, WHITE)
        _label(over, "Alle Operatoren wurden über das Match-Ergebnis informiert.", Vector2(39, 183), Vector2(717, 36), 17, MUTED)
        _button(over, "ZURÜCK ZUM HAUPTMENÜ", Vector2(40, 250), Vector2(715, 57), func(): _leave_match(), tint, true)

func _leave_match() -> void:
    match_game._disconnect_peer()
    match_game.reset_state()
    action_mode = "move"
    previous_event = ""
    status_text = "LOCAL SYSTEM READY"

func _update_profile(key: String, value: Variant) -> void:
    match_game.my_profile[key] = value
    match_game.request_profile_update()
    if key == "name" and str(value) == "":
        match_game.my_profile[key] = "GHOST"
    _rebuild_ui()

func _action_pressed(value: String) -> void:
    if value in ["interact", "overwatch"]:
        match_game.issue_action(value)
    else:
        action_mode = value
        status_text = "TARGETING // %s - Klick auf ein Feld" % value.to_upper()
        _rebuild_ui()

func _on_cell_clicked(cell: Vector2i) -> void:
    if match_game.state["phase"] != "battle": return
    if int(match_game.state["active"]) != match_game.local_id: return
    if action_mode in ["move", "fire"]:
        match_game.issue_action(action_mode, cell)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    if match_game.state["phase"] != "battle": return
    if event.keycode == KEY_SPACE:
        match_game.issue_action("end")
    elif event.keycode == KEY_1: _action_pressed("move")
    elif event.keycode == KEY_2: _action_pressed("fire")
    elif event.keycode == KEY_3: _action_pressed("interact")
    elif event.keycode == KEY_4: _action_pressed("overwatch")
