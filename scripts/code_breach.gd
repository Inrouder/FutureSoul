class_name CodeBreach
extends Control

signal completed(proof: Array, terminal_cell: Vector2i)
signal dismissed

const YELLOW := Color("f7ed17")
const DARK := Color("070a08")
const AQUA := Color("46e8d4")
const GREY := Color("788878")

var node_id := 0
var cell := Vector2i.ZERO
var matrix: Array = []
var chosen: Array = []
var buttons: Array = []
var buffer_label: Label
var warning: Label
var time_label: Label
var remaining := 55.0

func initialize(node: int, target: Vector2i) -> void:
    node_id = node
    cell = target
    matrix = BreachRules.matrix_for(node)
    chosen.clear()
    remaining = 55.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var cover := ColorRect.new()
    cover.color = Color("020503", 0.94)
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(cover)
    var outer := Panel.new()
    outer.position = Vector2(223, 88)
    outer.size = Vector2(994, 722)
    var style := StyleBoxFlat.new()
    style.bg_color = DARK
    style.border_color = YELLOW
    style.set_border_width_all(3)
    outer.add_theme_stylebox_override("panel", style)
    add_child(outer)
    _label(outer, "// FUTURESOUL CYBERDECK    SECURE ACCESS", Vector2(27, 22), 28, YELLOW)
    _label(outer, "BREACH PROTOCOL  /  CODE MATRIX", Vector2(28, 89), 17, AQUA)
    _label(outer, "BUFFER  04", Vector2(558, 90), 17, YELLOW)
    time_label = _label(outer, "TIME   55.0s", Vector2(793, 90), 17, YELLOW)
    var highlight := ColorRect.new()
    highlight.color = YELLOW
    highlight.position = Vector2(28, 135)
    highlight.size = Vector2(497, 6)
    outer.add_child(highlight)
    for y in range(BreachRules.GRID):
        var row: Array = []
        for x in range(BreachRules.GRID):
            var b := Button.new()
            b.position = Vector2(30 + x * 98, 168 + y * 82)
            b.size = Vector2(88, 69)
            b.text = str(matrix[y][x])
            b.focus_mode = Control.FOCUS_NONE
            b.add_theme_font_size_override("font_size", 25)
            var xx := x
            var yy := y
            b.pressed.connect(func(): _choose(xx, yy))
            outer.add_child(b)
            row.append(b)
        buttons.append(row)
    buffer_label = _label(outer, "--  --  --  --", Vector2(556, 149), 28, YELLOW)
    _label(outer, "SEQUENCE REQUIRED TO UPLOAD", Vector2(558, 226), 16, AQUA)
    for i in range(BreachRules.REQUIRED.size()):
        _label(outer, "%02d   %s" % [i + 1, BreachRules.REQUIRED[i]], Vector2(579, 273 + i * 64), 24, YELLOW)
    warning = _label(outer, "START IN TOP ROW // THEN COLUMN / ROW", Vector2(30, 624), 15, AQUA)
    var abort := Button.new()
    abort.position = Vector2(726, 618)
    abort.size = Vector2(231, 56)
    abort.text = "ABORT [ESC]"
    abort.add_theme_font_size_override("font_size", 18)
    abort.pressed.connect(func(): dismissed.emit())
    outer.add_child(abort)
    _refresh_buttons()

func _label(parent: Control, value: String, pos: Vector2, size: int, tint: Color) -> Label:
    var l := Label.new()
    l.text = value
    l.position = pos
    l.size = Vector2(600, 54)
    l.add_theme_color_override("font_color", tint)
    l.add_theme_font_size_override("font_size", size)
    parent.add_child(l)
    return l

func _process(delta: float) -> void:
    remaining -= delta
    if time_label:
        time_label.text = "TIME   %04.1fs" % maxf(0.0, remaining)
    if remaining <= 0.0:
        dismissed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        dismissed.emit()
        get_viewport().set_input_as_handled()

func _is_selectable(x: int, y: int) -> bool:
    if chosen.is_empty(): return y == 0
    var last: Array = chosen.back()
    if chosen.size() % 2 == 1: return x == int(last[0]) and y != int(last[1])
    return y == int(last[1]) and x != int(last[0])

func _choose(x: int, y: int) -> void:
    if not _is_selectable(x, y): return
    for old in chosen:
        if int(old[0]) == x and int(old[1]) == y: return
    chosen.append([x, y])
    var values: Array = []
    for pos in chosen: values.append(str(matrix[int(pos[1])][int(pos[0])]))
    while values.size() < 4: values.append("--")
    buffer_label.text = "  ".join(values)
    if chosen.size() == BreachRules.REQUIRED.size():
        if BreachRules.path_is_valid(node_id, chosen):
            set_process(false)
            completed.emit(chosen.duplicate(true), cell)
            return
        chosen.clear()
        warning.text = "SEQUENCE REJECTED // TRY AGAIN"
        warning.add_theme_color_override("font_color", Color("ff466c"))
    _refresh_buttons()

func _refresh_buttons() -> void:
    for y in range(BreachRules.GRID):
        for x in range(BreachRules.GRID):
            var b: Button = buttons[y][x]
            var allowed := _is_selectable(x, y)
            b.disabled = not allowed
            var selected := false
            for entry in chosen:
                if int(entry[0]) == x and int(entry[1]) == y: selected = true
            var flat := StyleBoxFlat.new()
            flat.bg_color = Color("9a8925") if selected else (Color("28321b") if allowed else Color("0f1710"))
            flat.border_color = YELLOW if selected else (AQUA if allowed else Color("394125"))
            flat.set_border_width_all(2 if allowed else 1)
            b.add_theme_stylebox_override("normal", flat)
            b.add_theme_stylebox_override("hover", flat)
            b.add_theme_stylebox_override("disabled", flat)
            b.add_theme_color_override("font_color", YELLOW)
            b.add_theme_color_override("font_disabled_color", GREY)
