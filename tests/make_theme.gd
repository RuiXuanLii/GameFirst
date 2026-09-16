extends SceneTree
func _initialize() -> void:
    var maker: Script = load("res://ui/theme_factory.gd")
    var result: Error = ResourceSaver.save(maker.create_theme(),"res://ui/jianghu_theme.tres")
    quit(0 if result == OK else 1)
