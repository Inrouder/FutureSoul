class_name FutureArena
extends Node2D

signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

const TILE := 32
const W := GameRules.WIDTH
const H := GameRules.HEIGHT
const ROOT := "res://assets/tiles/"
var terrain: Dictionary = {}
var blockers: Dictionary = {}
var highlight: Vector2i = Vector2i(-1, -1)
var selection: Vector2i = Vector2i(-1, -1)
var actor_node: Node2D
var textures: Dictionary = {}
var flicker := 0.0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for key in ["floor_0", "floor_1", "floor_2", "floor_3", "floor_4", "wall", "crate", "console", "neon", "puddle", "hazard", "extract", "hostage"]:
        textures[key] = load(ROOT + key + ".png")
    _create_map()
    actor_node = Node2D.new()
    actor_node.name = "Units"
    actor_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(actor_node)
    set_process(true)

func _create_map() -> void:
    terrain.clear()
    blockers.clear()
    for x in range(W):
        for y in range(H):
            if x == 0 or y == 0 or x == W - 1 or y == H - 1:
                set_tile(Vector2i(x, y), "wall")
    for y in range(2, 8):
        if y != 5:
            set_tile(Vector2i(8, y), "wall")
    for x in range(10, 16):
        if x != 13:
            set_tile(Vector2i(x, 4), "wall")
    for y in range(11, 17):
        if y != 14:
            set_tile(Vector2i(19, y), "wall")
    for x in range(11, 18):
        if x != 14:
            set_tile(Vector2i(x, 13), "wall")
    for y in range(3, 8):
        if y != 6:
            set_tile(Vector2i(20, y), "wall")
    for x in range(21, 26):
        if x != 23:
            set_tile(Vector2i(x, 12), "wall")
    for cell in [Vector2i(5, 5), Vector2i(6, 12), Vector2i(10, 9), Vector2i(14, 8), Vector2i(16, 10), Vector2i(11, 16), Vector2i(22, 4), Vector2i(24, 14), Vector2i(23, 16)]:
        set_tile(cell, "crate")
    for cell in [Vector2i(10, 3), Vector2i(17, 6), Vector2i(22, 15)]:
        set_tile(cell, "console")
    for cell in [Vector2i(3, 3), Vector2i(25, 3), Vector2i(18, 3), Vector2i(9, 16)]:
        set_tile(cell, "neon")
    for cell in [Vector2i(7, 16), Vector2i(15, 5), Vector2i(25, 10), Vector2i(12, 10)]:
        set_tile(cell, "puddle")
    for x in range(2, 5):
        for y in range(8, 12):
            set_tile(Vector2i(x, y), "extract")
    for x in range(21, 25):
        set_tile(Vector2i(x, 8), "hazard")

func set_tile(cell: Vector2i, kind: String) -> void:
    terrain[cell] = kind
    if kind in ["wall", "crate", "console", "neon"]:
        blockers[cell] = true
    else:
        blockers.erase(cell)

func is_blocked(cell: Vector2i) -> bool:
    return not GameRules.in_bounds(cell) or blockers.has(cell)

func tile_at(cell: Vector2i) -> String:
    return terrain.get(cell, "floor")

func walkable_blockers() -> Dictionary:
    return blockers.duplicate()

func is_extract(cell: Vector2i) -> bool:
    return tile_at(cell) == "extract"

func cell_center(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * TILE + 16, cell.y * TILE + 16)

func cell_from_screen(screen: Vector2) -> Vector2i:
    var local := to_local(screen)
    return Vector2i(floori(local.x / TILE), floori(local.y / TILE))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var cell := cell_from_screen(get_global_mouse_position())
        if GameRules.in_bounds(cell) and cell != highlight:
            highlight = cell
            cell_hovered.emit(cell)
            queue_redraw()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var cell := cell_from_screen(get_global_mouse_position())
        if GameRules.in_bounds(cell):
            cell_clicked.emit(cell)
            get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    flicker += delta
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-5, -5, W * TILE + 10, H * TILE + 10), Color("070b13"))
    draw_rect(Rect2(-2, -2, W * TILE + 4, H * TILE + 4), Color("50dece"), false, 2)
    for y in range(H):
        for x in range(W):
            var c := Vector2i(x, y)
            var kind: String = tile_at(c)
            var pos := Vector2(x * TILE, y * TILE)
            if kind == "floor":
                kind = "floor_" + str((x * 19 + y * 37 + x * y * 3) % 5)
            draw_texture(textures[kind], pos)
            if (x * 17 + y * 29) % 37 == 0 and kind.begins_with("floor"):
                draw_rect(Rect2(pos + Vector2(12, 8), Vector2(2, 1)), Color("d48764", 0.43))
    # Lamps and monitor glow, cheap enough for a pixel-art 2D scene.
    for glow_cell in [Vector2i(3, 3), Vector2i(25, 3), Vector2i(18, 3), Vector2i(9, 16)]:
        var p := cell_center(glow_cell)
        var pulse := 0.83 + sin(flicker * 1.8 + glow_cell.x) * 0.17
        for radius in [70.0, 45.0, 25.0]:
            draw_circle(p, radius, Color(0.1, 0.91, 0.81, 0.008 * pulse * (80.0 / radius)))
    for x in range(2, 5):
        for y in range(8, 12):
            draw_rect(Rect2(Vector2(x * TILE, y * TILE), Vector2(TILE, TILE)), Color(0.2, 1.0, 0.76, 0.04 + 0.05 * sin(flicker * 3.0)), true)
    # subtle digital night-time atmosphere
    draw_rect(Rect2(0, 0, W * TILE, H * TILE), Color(0.025, 0.04, 0.11, 0.12))
    if GameRules.in_bounds(selection):
        draw_rect(Rect2(Vector2(selection * TILE), Vector2(TILE, TILE)), Color("ffe49c"), false, 2)
    if GameRules.in_bounds(highlight):
        draw_rect(Rect2(Vector2(highlight * TILE), Vector2(TILE, TILE)), Color("50f4db", 0.85), false, 1)
