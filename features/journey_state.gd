extends RefCounted

const World: Script = preload("res://features/world_data.gd")
var location: String = "town"
var day: int = 1
var aptitudes: Dictionary = {"根骨": 6, "悟性": 7, "魅力": 5}
var personality: String = "刚烈"
var yin: int = 0
var yang: int = 0
var manuals: Array[String] = []
var skills: Array[String] = []
var active_manual: String = ""
var active_skill: String = ""
var visited: Array[String] = ["town"]
var journal: Array[String] = ["你在临江镇醒来，决定先向江湖求学。"]

func note(message: String) -> void:
    journal.append("第 %d 日 · %s" % [day, message])
    if journal.size() > 30:
        journal.pop_front()

func travel(destination: String) -> bool:
    var place: Dictionary = World.PLACES[location]
    if not destination in place.links:
        return false
    location = destination
    day += 1
    if not location in visited:
        visited.append(location)
    note("抵达" + str(World.PLACES[location].title))
    return true

func learn() -> bool:
    var place: Dictionary = World.PLACES[location]
    var manual_id: String = str(place.get("manual", ""))
    if manual_id.is_empty() or manual_id in manuals:
        return false
    var skill_id: String = str(place.skill)
    manuals.append(manual_id)
    skills.append(skill_id)
    active_manual = manual_id
    active_skill = skill_id
    note("获授《%s》与%s。" % [World.MANUALS[manual_id].title, World.SKILLS[skill_id].title])
    return true

func choose_manual(manual_id: String) -> bool:
    if not manual_id in manuals:
        return false
    active_manual = manual_id
    return true

func cultivate() -> bool:
    if active_manual.is_empty():
        return false
    if World.MANUALS[active_manual].polarity == "阴":
        yin = mini(yin + 2, 100)
    else:
        yang = mini(yang + 2, 100)
    day += 1
    note("修炼《%s》，内息渐长；初始资质不变。" % World.MANUALS[active_manual].title)
    return true

func equip(skill_id: String) -> bool:
    if not skill_id in skills:
        return false
    active_skill = skill_id
    return true

func practice(provoked: bool) -> Dictionary:
    if active_skill.is_empty():
        return {}
    var polarity: String = str(World.SKILLS[active_skill].polarity)
    var reserve: int = yin if polarity == "阴" else yang
    var aligned: bool = not active_manual.is_empty() and World.MANUALS[active_manual].polarity == polarity
    var mood: String = "激愤" if provoked and personality == "刚烈" else "平心"
    var power: float = (10.0 + float(reserve) * 1.5) * (1.15 if aligned else 1.0)
    var guard: float = 1.0
    if mood == "激愤":
        power *= 1.25
        guard = 0.8
    return {"skill": active_skill, "power": snappedf(power, 0.1), "guard": guard, "mood": mood, "aligned": aligned, "reason": "刚烈性格受到挑衅：攻势增强，守势降低。" if mood == "激愤" else "无人挑衅，保持平常心。"}

func snapshot() -> Dictionary:
    return {"version": 1, "location": location, "day": day, "aptitudes": aptitudes.duplicate(true), "personality": personality, "yin": yin, "yang": yang, "manuals": manuals.duplicate(), "skills": skills.duplicate(), "active_manual": active_manual, "active_skill": active_skill, "visited": visited.duplicate(), "journal": journal.duplicate()}

func restore(data: Dictionary) -> bool:
    if data.get("version") != 1 or not data.get("location", "") in World.PLACES:
        return false
    for field: String in ["day", "yin", "yang"]:
        var value: Variant = data.get(field)
        if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floorf(float(value)):
            return false
    if int(data.day) < 1 or int(data.day) > 1000000 or int(data.yin) < 0 or int(data.yin) > 100 or int(data.yang) < 0 or int(data.yang) > 100:
        return false
    if not data.get("aptitudes") is Dictionary or data.aptitudes.size() != 3 or data.get("personality") != "刚烈":
        return false
    var expected: Dictionary = {"根骨": 6, "悟性": 7, "魅力": 5}
    for key: String in expected:
        var aptitude: Variant = data.aptitudes.get(key)
        if not (aptitude is int or aptitude is float) or float(aptitude) != float(expected[key]):
            return false
    for field: String in ["manuals", "skills", "visited", "journal"]:
        if not data.get(field) is Array or data[field].size() > 100:
            return false
        for value: Variant in data[field]:
            if not value is String or value.length() > 400:
                return false
    for entry: String in data.manuals:
        if not entry in World.MANUALS or data.manuals.count(entry) != 1:
            return false
    for entry: String in data.skills:
        if not entry in World.SKILLS or data.skills.count(entry) != 1:
            return false
    for entry: String in data.visited:
        if not entry in World.PLACES or data.visited.count(entry) != 1:
            return false
    if not data.location in data.visited or not "town" in data.visited:
        return false
    if data.manuals.size() != data.skills.size():
        return false
    if ("qinglan" in data.manuals) != ("sword" in data.skills) or ("zhenyue" in data.manuals) != ("palm" in data.skills):
        return false
    if not data.get("active_manual", "") in data.manuals and not (data.manuals.is_empty() and data.get("active_manual") == ""):
        return false
    if not data.get("active_skill", "") in data.skills and not (data.skills.is_empty() and data.get("active_skill") == ""):
        return false
    location = str(data.location)
    day = int(data.day)
    yin = int(data.yin)
    yang = int(data.yang)
    manuals.assign(data.manuals)
    skills.assign(data.skills)
    visited.assign(data.visited)
    journal.assign(data.journal)
    active_manual = str(data.active_manual)
    active_skill = str(data.active_skill)
    return true
