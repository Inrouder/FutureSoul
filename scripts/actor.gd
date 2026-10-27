class_name FutureActor
extends Node2D

var role := "runner"
var class_id := "e_runner"
var faction := "edgerunner"
var stealth := 0
var shield := 0
var jammed := 0
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
    class_id = str(profile.get("class_id", "e_runner"))
    faction = str(profile.get("faction", "edgerunner"))
    role = "heavy" if class_id in ["m_gunner", "e_big", "k_rocky", "heavy"] else ("netrunner" if class_id in ["e_runner", "k_raven", "netrunner"] else "runner")
    color_id = clampi(int(profile.get("color_id", 0)), 0, 3)
    team = str(profile.get("team", "edge"))
    if faction == "maelstrom":
        role = "punk"
    stealth = int(profile.get("stealth", 0))
    shield = int(profile.get("shield", 0))
    jammed = int(profile.get("jam", 0))
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
    if stealth > 0:
        draw_circle(Vector2.ZERO, 23, Color(0.15, 0.96, 0.82, 0.11))
        draw_arc(Vector2.ZERO, 23, -PI / 2, PI * 1.5, 27, Color("49ecd5", 0.85), 2)
    if shield > 0:
        draw_arc(Vector2.ZERO, 24, 0, TAU, 32, Color("ffcf68", 0.77), 2)
    if avatar:
        draw_texture(avatar, Vector2(-16, -18))
    # Additional readable cyberware silhouettes distinguish the ten class roles.
    match class_id:
        "k_first":
            draw_line(Vector2(8, 7), Vector2(25, -22), Color("fdfcf3"), 4)
            draw_line(Vector2(9, 5), Vector2(25, -22), Color("fd4d70"), 2)
            draw_rect(Rect2(-7, -10, 14, 3), Color("d9c78d"))
        "k_raven":
            draw_polyline(PackedVector2Array([Vector2(-21, -12), Vector2(-14, -18), Vector2(-19, -21), Vector2(-9, -28)]), Color("5debf6"), 2)
            draw_polyline(PackedVector2Array([Vector2(16, 7), Vector2(22, 0), Vector2(18, -5), Vector2(26, -12)]), Color("9d80ff"), 2)
        "k_rocky":
            draw_rect(Rect2(-23, -15, 9, 24), Color("d9e4b3"))
            draw_rect(Rect2(-21, -13, 5, 20), Color("4bcac0"))
            draw_line(Vector2(12, 12), Vector2(26, -18), Color("e6b96b"), 5)
        "e_sniper":
            draw_line(Vector2(9, 0), Vector2(37, -9), Color("b7c7d5"), 4)
            draw_line(Vector2(29, -10), Vector2(36, -12), Color("53e1dc"), 2)
        "e_big":
            draw_rect(Rect2(12, -9, 20, 9), Color("e7c497"))
            draw_rect(Rect2(25, -12, 10, 5), Color("e3f0ec"))
        "e_psycho":
            draw_line(Vector2(-14, 9), Vector2(-24, -9), Color("fe607d"), 4)
            draw_line(Vector2(14, 9), Vector2(24, -9), Color("fe607d"), 4)
        "e_runner":
            draw_arc(Vector2(14, 2), 13, 0.0, PI * 1.5, 13, Color("52f0ed"), 2)
        "m_gunner":
            draw_rect(Rect2(11, -11, 24, 12), Color("87868e"))
            draw_rect(Rect2(31, -10, 8, 7), Color("ffac58"))
        "m_brawler":
            draw_rect(Rect2(-22, -12, 8, 10), Color("b3acbf"))
            draw_rect(Rect2(13, -11, 8, 9), Color("fd5574"))
        "m_shooty":
            draw_rect(Rect2(12, -8, 25, 8), Color("ebaa5a"))
    if jammed > 0:
        draw_line(Vector2(-16, -15), Vector2(-5, -27), Color("f4d84c"), 2)
    draw_rect(Rect2(-16, -26, 32, 3), Color("0b1120"))
    var full_hp: float = float(GameRules.CLASSES[class_id]["health"])
    draw_rect(Rect2(-15, -25, clampf(float(health) / full_hp * 30.0, 0.0, 30.0), 1), Color("63e5b0") if health > 30 else Color("fb5369"))
    if carrying:
        draw_circle(Vector2(0, -34), 3, Color("f6c66d"))
    if font:
        draw_string(font, Vector2(-16, -31), nickname.left(9), HORIZONTAL_ALIGNMENT_LEFT, 52, 10, Color("e4eafa"))
