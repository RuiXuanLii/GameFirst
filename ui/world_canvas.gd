extends Control

signal destination_selected(destination: String)
const World: Script = preload("res://features/world_data.gd")
var current: String = "town"
var selected: String = "town"
var visited: Array[String] = ["town"]
var elapsed: float = 0.0
var places: Dictionary = {}

func _ready() -> void:
    custom_minimum_size = Vector2(360, 280)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    clip_contents = true
    for key: String in World.PLACES:
        var button: Button = Button.new()
        button.name = key
        button.text = str(World.PLACES[key].title)
        button.custom_minimum_size = Vector2(114, 36)
        button.pressed.connect(func() -> void: destination_selected.emit(key))
        add_child(button)
        places[key] = button
    resized.connect(_place_buttons)
    _place_buttons()

func _place_buttons() -> void:
    for key: String in places:
        var button: Button = places[key]
        button.position = _point(key) + Vector2(-57, 18)
        button.size = Vector2(114, 36)
    queue_redraw()

func _point(key: String) -> Vector2:
    var point: Vector2 = World.PLACES[key].point
    return Vector2(24, 30) + point * (size - Vector2(48, 90))

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("142927"))
    for x: int in range(0, int(size.x), 32):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.6, 0.7, 0.5, 0.035))
    for y: int in range(0, int(size.y), 32):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.7, 0.5, 0.035))
    # Stylized ridgelines and river are native geometry, not imported artwork.
    for index: int in range(22):
        var mx: float = fmod(float(index) * 117.0 + 30.0, maxf(size.x - 60, 1))
        var my: float = fmod(float(index) * 73.0 + 40.0, maxf(size.y - 80, 1))
        var peak: PackedVector2Array = PackedVector2Array([Vector2(mx - 20, my + 20), Vector2(mx, my - 18), Vector2(mx + 24, my + 20)])
        draw_colored_polygon(peak, Color("203b33"))
        draw_polyline(peak, Color("3c5242"), 1.0)
    var river: PackedVector2Array = PackedVector2Array()
    for index: int in range(50):
        var t: float = float(index) / 49.0
        river.append(Vector2(t * size.x, size.y * (0.45 + sin(t * 8.0) * 0.10)))
    draw_polyline(river, Color("234744"), 15.0, true)
    draw_polyline(river, Color("426a60"), 1.5, true)
    for key: String in World.PLACES:
        for target: String in World.PLACES[key].links:
            if key < target:
                var color: Color = Color("ac9967") if key == current or target == current else Color("536152")
                draw_dashed_line(_point(key), _point(target), color, 2.0, 7.0)
    var font: Font = get_theme_default_font()
    draw_string(font, Vector2(24, 32), "江 湖 舆 图", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("dfc58a"))
    draw_string(font, Vector2(24, size.y - 20), "点选地名查看 · 沿相连路线旅行", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9ba994"))
    for key: String in World.PLACES:
        var p: Vector2 = _point(key)
        draw_circle(p, 9.0, Color("d3b87b") if key in visited else Color("6b7963"))
        draw_circle(p, 4.0, Color("152c29"))
        if key == selected:
            draw_arc(p, 14, 0, TAU, 40, Color("e7cc8f"), 1.5, true)
        if key == current:
            draw_arc(p, 19 + sin(elapsed * 2.0) * 2.0, 0, TAU, 40, Color("72c5ac"), 2.0, true)
