extends SceneTree
const Store: Script = preload("res://features/save_store.gd")
const Rules: Script = preload("res://features/journey_state.gd")
var failures: int = 0
func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        print("FAIL: " + message)
func _initialize() -> void:
    var path: String = "user://test_backup_only.json"
    for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
        if FileAccess.file_exists(path+suffix):
            DirAccess.remove_absolute(path+suffix)
    var state: RefCounted = Rules.new()
    check(Store.save_state(state,path) == OK, "Initial save")
    state.travel("ferry")
    check(Store.save_state(state,path) == OK, "Second save")
    check(FileAccess.file_exists(path+".bak"), "Prior save backed up before replacement")
    var broken: FileAccess = FileAccess.open(path,FileAccess.WRITE)
    broken.store_string("{broken")
    broken.close()
    var recovered: RefCounted = Rules.new()
    recovered.travel("ridge")
    check(Store.load_state(recovered,path) == OK and recovered.location == "town", "Corrupt primary recovers previous validated save")
    check(FileAccess.get_file_as_string(path) == "{broken", "Recovery does not overwrite damaged file")
    DirAccess.remove_absolute(path)
    recovered.travel("ridge")
    check(Store.load_state(recovered,path) == OK and recovered.location == "town", "Missing primary after interrupted replacement recovers backup")
    broken = FileAccess.open(path+".bak",FileAccess.WRITE)
    broken.store_string("bad backup")
    broken.close()
    var snapshot: Dictionary = recovered.snapshot()
    check(Store.load_state(recovered,path) != OK and recovered.snapshot() == snapshot, "No usable save leaves memory intact")
    for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
        if FileAccess.file_exists(path+suffix):
            DirAccess.remove_absolute(path+suffix)
    print("SAVE TESTS: %d failures" % failures)
    quit(1 if failures else 0)
