class_name FutureActor
extends Node2D

var role := "runner"
var color_id := 0
var team := "edge"
var is_active := false
var is_dead := false
var health := 100
var carrying := false
var nickname := ""
var avatar: Texture2D
var pulse := 0.0
var font: Font

func configure(profile: Dictionary) -> void:
    role = str(profile.get("class_id", "runner"))
    if team == "punk":
        role = "punk"
    color_id = clampi(int(profile.get("color_id", 0)), 0, 3)
    team = str(profile.get("team", "edge"))
    if team == "punk":
        role = "punk"
    is_active = bool(profile.get("active", false))
    is_dead = int(profile.get("hp", 0)) <= 0
    health = int(profile.get("hp", 100))
    carrying = bool(profile.get("carrying", false))
    nickname = str(profile.get("name", "OPERATOR"))
    avatar = load("res://assets/units/%s_%d.png" % [role, color_id])
    font = ThemeDB.fallback_font
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    queue_redraw()

func _draw() -> void:
    if is_dead:
        draw_circle(Vector2(0, 6), 13, Color("1a202d"))
        draw_line(Vector2(-7, -4), Vector2(7, 9), Color("c13b5c"), 3)
        draw_line(Vector2(7, -4), Vector2(-7, 9), Color("c13b5c"), 3)
        return
    var col := Color("49ead6") if team == "edge" else Color("ff4c71")
    draw_circle(Vector2(0, 5), 17, Color(0.0, 0.0, 0.0, 0.38))
    draw_arc(Vector2.ZERO, 18.0 + (1.0 + sin(pulse * 3.0)) if is_active else 18.0, 0, TAU, 32, col, 2.3 if is_active else 1.15)
    if avatar:
        draw_texture(avatar, Vector2(-16, -18))
    draw_rect(Rect2(-16, -26, 32, 3), Color("0b1120"))
    draw_rect(Rect2(-15, -25, maxf(0.0, health / (130.0 if role == "heavy" else 100.0) * 30.0), 1), Color("63e5b0") if health > 30 else Color("fb5369"))
    if carrying:
        draw_circle(Vector2(0, -34), 3, Color("f6c66d"))
    if font:
        draw_string(font, Vector2(-16, -31), nickname.left(9), HORIZONTAL_ALIGNMENT_LEFT, 52, 10, Color("e4eafa"))
