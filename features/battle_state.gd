extends RefCounted
var journey: RefCounted
var player_hp: int = 100
var enemy_hp: int = 65
var energy: int = 4
var turn: int = 1
var finished: bool = false
var won: bool = false

func begin(source: RefCounted) -> void:
    journey = source
    player_hp = 100
    enemy_hp = 65
    energy = 4
    turn = 1
    finished = false
    won = false

func act(action: String) -> Dictionary:
    if finished or not action in ["basic", "technique", "guard"]:
        return {}
    if action == "technique" and (energy < 2 or journey.active_skill.is_empty()):
        return {}
    var provoked: bool = turn % 3 == 0
    var expression: Dictionary = journey.practice(provoked)
    var mood: String = str(expression.get("mood", "平心"))
    var defense: float = float(expression.get("guard", 1.0))
    var damage: int = 0
    if action == "technique":
        damage = maxi(1, roundi(float(expression.power)))
        energy -= 2
    elif action == "basic":
        damage = 9 if mood == "激愤" else 7
        energy = mini(4, energy + 1)
    else:
        energy = mini(4, energy + 2)
    enemy_hp = maxi(0, enemy_hp - damage)
    var incoming: int = 0
    if enemy_hp > 0:
        incoming = roundi((16.0 if turn % 2 == 0 else 10.0) / defense)
        if action == "guard":
            incoming = roundi(float(incoming) * 0.3)
        player_hp = maxi(0, player_hp - incoming)
    finished = enemy_hp == 0 or player_hp == 0
    won = finished and enemy_hp == 0 and player_hp > 0
    var result: Dictionary = {"action": action, "damage": damage, "incoming": incoming, "mood": mood, "provoked": provoked, "skill": journey.active_skill, "finished": finished, "won": won}
    turn += 1
    return result
