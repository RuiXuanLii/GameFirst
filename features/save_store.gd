extends RefCounted

const Rules: Script = preload("res://features/journey_state.gd")
const SAVE_PATH: String = "user://first_journey_v1.json"
static var recovered_backup: bool = false

static func save_state(state: RefCounted, path: String = SAVE_PATH) -> Error:
    var data: Dictionary = state.snapshot()
    var validator: RefCounted = Rules.new()
    if not validator.restore(data):
        return ERR_INVALID_DATA
    var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(data, "  "))
    file.flush()
    var result: Error = file.get_error()
    file.close()
    if result != OK:
        return result
    if _read(validator, path + ".tmp") != OK:
        return ERR_FILE_CORRUPT
    # Windows replacement may delete the destination before moving the new file.
    # Preserve a verified prior generation before touching the primary file.
    if FileAccess.file_exists(path) and _read(validator, path) == OK:
        result = DirAccess.copy_absolute(path, path + ".bak.tmp")
        if result != OK:
            return result
        if _read(validator, path + ".bak.tmp") != OK:
            return ERR_FILE_CORRUPT
        result = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
        if result != OK:
            return result
    return DirAccess.rename_absolute(path + ".tmp", path)

static func load_state(state: RefCounted, path: String = SAVE_PATH) -> Error:
    recovered_backup = false
    var result: Error = _read(state, path)
    if result == OK:
        return OK
    if _read(state, path + ".bak") == OK:
        recovered_backup = true
        return OK
    return result

static func _read(state: RefCounted, path: String) -> Error:
    if not FileAccess.file_exists(path):
        return ERR_FILE_NOT_FOUND
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()
    var parser: JSON = JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        return ERR_INVALID_DATA
    var data: Variant = parser.data
    if not data is Dictionary or not state.restore(data):
        return ERR_INVALID_DATA
    return OK
