extends SceneTree
var failures: int = 0
func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        print("FAIL: " + message)
func _initialize() -> void:
    if not ResourceLoader.exists("res://features/battle_state.gd"):
        print("FAIL: Turn battle is not implemented")
        quit(1)
        return
    var rules: Script = load("res://features/battle_state.gd")
    var journey: RefCounted = load("res://features/journey_state.gd").new()
    journey.travel("ferry")
    journey.travel("qinglan")
    journey.learn()
    journey.cultivate()
    var day_before: int = journey.day
    var battle: RefCounted = rules.new()
    battle.begin(journey)
    check(battle.act("invalid").is_empty(), "Invalid action rejected")
    var first: Dictionary = battle.act("technique")
    check(not first.is_empty() and battle.energy == 2, "Technique consumes energy")
    battle.act("technique")
    var hp_before: int = battle.player_hp
    check(battle.act("technique").is_empty() and battle.player_hp == hp_before, "Insufficient energy does not advance turn")
    var guarded: Dictionary = battle.act("guard")
    check(battle.energy > 0 and guarded.incoming < 10, "Guard reduces damage and recovers energy")
    var attempts: int = 0
    while not battle.finished and attempts < 30:
        battle.act("basic")
        attempts += 1
    check(battle.finished, "Battle reaches terminal state")
    check(battle.act("basic").is_empty(), "No actions after battle ends")
    check(journey.day == day_before, "Battle rounds do not consume cultivation days")
    battle.begin(journey)
    check(battle.player_hp == 100 and battle.enemy_hp == 65 and battle.turn == 1, "Restart resets transient combat state")
    print("BATTLE TESTS: %d failures" % failures)
    quit(1 if failures else 0)
