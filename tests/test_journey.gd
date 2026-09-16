extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        print("FAIL: " + message)

func _initialize() -> void:
    if not ResourceLoader.exists("res://features/journey_state.gd"):
        print("FAIL: Journey rules are not implemented")
        quit(1)
        return
    var rules: Script = load("res://features/journey_state.gd")
    var state: RefCounted = rules.new()
    var original: Dictionary = state.aptitudes.duplicate(true)
    check(not state.learn(), "Cannot learn a sect art in the starting town")
    check(not state.travel("qinglan"), "Cannot teleport to a nonadjacent place")
    check(state.travel("ferry"), "Can travel to connected ferry")
    check(state.travel("qinglan"), "Can reach northern sect")
    check(state.learn(), "Can learn northern transmission")
    check(not state.learn(), "Cannot duplicate transmission")
    check(state.skills.size() == 1, "One learned skill")
    check(state.cultivate(), "Can cultivate learned manual")
    check(state.yin > 0 and state.yang == 0, "Northern manual cultivates yin")
    check(state.travel("ferry") and state.travel("town") and state.travel("ridge") and state.travel("zhenyue"), "Travel between regions")
    check(state.learn(), "Can learn southern transmission without losing first")
    check(state.skills.size() == 2, "Two learned techniques coexist")
    check(state.cultivate(), "Can cultivate southern manual")
    check(state.yang > 0 and state.yin > 0, "Both internal histories preserved")
    check(not state.equip("unknown"), "Cannot equip unknown technique")
    check(state.equip("palm"), "Can equip learned palm")
    var calm: Dictionary = state.practice(false)
    var anger: Dictionary = state.practice(true)
    check(float(anger.power) > float(calm.power), "Provocation changes fierce character performance")
    check(float(anger.guard) < float(calm.guard), "Anger has defensive cost")
    check(state.practice(false).mood == "平心", "Temporary mood does not leak")
    check(state.aptitudes == original, "Daily progression cannot raise aptitudes")
    var saved: Dictionary = state.snapshot()
    var restored: RefCounted = rules.new()
    check(restored.restore(saved), "Valid snapshot restores")
    check(restored.snapshot() == saved, "Roundtrip preserves journey")
    var json_data: Dictionary = JSON.parse_string(JSON.stringify(saved))
    check(restored.restore(json_data), "JSON numeric roundtrip restores")
    var bad: Dictionary = saved.duplicate(true)
    bad["location"] = "missing"
    check(not restored.restore(bad), "Unknown saved location rejected")
    check(restored.snapshot() == saved, "Invalid save does not partly mutate state")
    bad = saved.duplicate(true)
    bad["aptitudes"] = {"根骨": 999}
    check(not restored.restore(bad), "Invalid aptitude data rejected")
    print("RULE TESTS: " + str(failures) + " failures")
    quit(1 if failures > 0 else 0)
