extends SceneTree
var failures: int = 0
var app: Control
var capture: bool = false

func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        print("FAIL: " + message)

func settle() -> void:
    for index: int in range(5):
        await process_frame

func click(id: String) -> void:
    check(app.action_buttons.has(id), "Action exists: " + id)
    if not app.action_buttons.has(id):
        return
    var target: Button = app.action_buttons[id]
    check(not target.disabled, "Action enabled: " + id)
    if not target.disabled:
        target.pressed.emit()
    await settle()

func visit(id: String) -> void:
    (app.map_canvas.places[id] as Button).pressed.emit()
    await settle()
    await click("travel")

func screenshot(path: String) -> void:
    if capture:
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        check(image.save_png(path) == OK, "Screenshot saved")

func inspect_layout(node: Node) -> void:
    if node is Control and node.is_visible_in_tree() and not node is ScrollContainer:
        var control: Control = node
        if control is Button and not _within_scroll(control):
            check(control.size.x > 0 and control.size.y > 0, "Nonzero control: " + str(control.get_path()))
            check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()), "Button on screen: " + str(control.get_path()))
        if control is Container and not control is SubViewportContainer:
            var children: Array[Control] = []
            for child: Node in control.get_children():
                if child is Control and child.is_visible_in_tree():
                    children.append(child)
            for i: int in range(children.size()):
                for j: int in range(i+1,children.size()):
                    check(not children[i].get_global_rect().intersects(children[j].get_global_rect()), "Sibling overlap: " + str(children[i].get_path()))
    for child: Node in node.get_children():
        if not child is SubViewport:
            inspect_layout(child)

func _within_scroll(node: Node) -> bool:
    var parent: Node = node.get_parent()
    while parent != null:
        if parent is ScrollContainer:
            return true
        parent = parent.get_parent()
    return false

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    capture = "--capture" in OS.get_cmdline_user_args()
    var scene: PackedScene = load("res://scenes/journey.tscn")
    app = scene.instantiate()
    root.add_child(app)
    await settle()
    for dimensions: Vector2i in [Vector2i(960,540), Vector2i(1280,800)]:
        root.size = dimensions
        root.content_scale_size = dimensions
        await settle()
        inspect_layout(app)
    await screenshot("res://artifacts/world.png")
    await visit("ferry")
    await visit("qinglan")
    await click("learn")
    var before: int = app.state.day
    await click("cultivate")
    check(app.state.day == before + 1, "Cultivation advances exactly one day")
    await click("battle")
    check(app.in_battle and app.viewport_box.visible and not app.map_canvas.visible, "2D switches to 3D")
    await screenshot("res://artifacts/battle.png")
    await click("technique")
    check(app.stage.busy, "Cinematic is running")
    check(app.action_buttons["basic"].disabled, "Commands locked during cinematic")
    await create_timer(2.4).timeout
    await settle()
    check(not app.stage.busy, "Cinematic returns control")
    await click("retreat")
    check(not app.in_battle and app.map_canvas.visible, "Returns to world")
    await visit("ferry")
    await visit("town")
    await visit("ridge")
    await visit("zhenyue")
    await click("learn")
    await click("cultivate")
    await click("tab_arts")
    await click("skill_sword")
    check(app.state.active_skill == "sword", "Cross-sect technique selection")
    await click("manual_qinglan")
    await click("tab_place")
    await click("battle")
    var rounds: int = 0
    while not app.battle.finished and rounds < 20:
        await click("technique" if app.battle.energy >= 2 else "basic")
        await create_timer(2.4).timeout
        await settle()
        rounds += 1
    check(app.battle.finished, "UI can complete battle")
    await click("leave_battle")
    check(not app.in_battle, "Result screen returns to map")
    var store: Script = load("res://features/save_store.gd")
    var save_path: String = "user://test_journey_only.json"
    check(store.save_state(app.state,save_path) == OK, "File save succeeds")
    check(store.save_state(app.state,save_path) == OK, "Existing file replacement succeeds")
    var restored: RefCounted = load("res://features/journey_state.gd").new()
    check(store.load_state(restored,save_path) == OK, "File load succeeds")
    check(restored.snapshot() == app.state.snapshot(), "File persistence roundtrip")
    var broken: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
    broken.store_string("{broken")
    broken.close()
    check(store.load_state(restored,save_path) == OK, "Corrupt primary recovers backup")
    check(store.recovered_backup, "Recovery is reported to UI")
    DirAccess.remove_absolute(save_path + ".bak")
    var prior: Dictionary = restored.snapshot()
    check(store.load_state(restored,save_path) == ERR_INVALID_DATA, "Corrupt save rejected")
    check(restored.snapshot() == prior, "Corrupt save preserves current state")
    check(FileAccess.get_file_as_string(save_path) == "{broken", "Corrupt file remains untouched")
    DirAccess.remove_absolute(save_path)
    print("UI JOURNEY: %d failures; %d combat rounds" % [failures,rounds])
    app.queue_free()
    await process_frame
    quit(1 if failures else 0)
