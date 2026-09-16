extends RefCounted

static func box(fill: Color, border: Color, radius: int = 6) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

static func create_theme() -> Theme:
    var result: Theme = Theme.new()
    var font: SystemFont = SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
    result.default_font = font
    result.default_font_size = 16
    result.set_color("font_color", "Label", Color("e3d9bc"))
    result.set_color("default_color", "RichTextLabel", Color("e3d9bc"))
    result.set_constant("separation", "VBoxContainer", 10)
    result.set_constant("separation", "HBoxContainer", 12)
    result.set_stylebox("panel", "PanelContainer", box(Color("192c2b"), Color("42534a")))
    result.set_stylebox("normal", "Button", box(Color("253c36"), Color("62705b")))
    result.set_stylebox("hover", "Button", box(Color("385345"), Color("d1b677")))
    result.set_stylebox("pressed", "Button", box(Color("172d27"), Color("dfc38c")))
    result.set_stylebox("disabled", "Button", box(Color("20302e"), Color("34433c")))
    var focus: StyleBoxFlat = box(Color(0, 0, 0, 0), Color("f4d190"))
    focus.set_border_width_all(2)
    result.set_stylebox("focus", "Button", focus)
    result.set_color("font_color", "Button", Color("f0e4c8"))
    result.set_color("font_disabled_color", "Button", Color("7f8a79"))
    return result
