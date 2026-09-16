extends Control

const World: Script = preload("res://features/world_data.gd")
const Rules: Script = preload("res://features/journey_state.gd")
const Store: Script = preload("res://features/save_store.gd")
const ThemeFactory: Script = preload("res://ui/theme_factory.gd")
const MapCanvas: Script = preload("res://ui/world_canvas.gd")
const BattleRules: Script = preload("res://features/battle_state.gd")
const BattleStage: Script = preload("res://ui/battle_stage.gd")
var state: RefCounted = Rules.new()
var battle: RefCounted = BattleRules.new()
var selected: String = "town"
var in_battle: bool = false
var page: String = "place"
var map_canvas: Control
var stage: Node3D
var viewport_box: SubViewportContainer
var battle_viewport: SubViewport
var sidebar: VBoxContainer
var heading: Label
var status: Label
var character: Label
var tabs: HBoxContainer
var new_dialog: ConfirmationDialog
var action_buttons: Dictionary = {}

func _ready() -> void:
    theme = ThemeFactory.create_theme()
    var bg: ColorRect = ColorRect.new()
    bg.color = Color("101f20")
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin: MarginContainer = MarginContainer.new()
    margin.name = "Layout"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 16)
    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.name = "Column"
    margin.add_child(root_box)
    var top: HBoxContainer = HBoxContainer.new()
    root_box.add_child(top)
    heading = label(top, "江湖初行", 27)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button(top, "保存", save_game, "save")
    button(top, "读档", load_game, "load")
    button(top, "新旅程", request_new, "new")
    character = label(root_box, "", 14)
    var body: HBoxContainer = HBoxContainer.new()
    body.name = "Body"
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_box.add_child(body)
    var left: VBoxContainer = VBoxContainer.new()
    left.name = "World"
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(left)
    map_canvas = MapCanvas.new()
    map_canvas.name = "Map"
    map_canvas.destination_selected.connect(select_place)
    left.add_child(map_canvas)
    viewport_box = SubViewportContainer.new()
    viewport_box.stretch = true
    viewport_box.custom_minimum_size = Vector2(360,280)
    viewport_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    viewport_box.visible = false
    left.add_child(viewport_box)
    battle_viewport = SubViewport.new()
    battle_viewport.size = Vector2i(640,400)
    battle_viewport.own_world_3d = true
    battle_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    viewport_box.add_child(battle_viewport)
    stage = BattleStage.new()
    battle_viewport.add_child(stage)
    stage.animation_finished.connect(_battle_animation_finished)
    var hint: Label = label(left, "山河可往，武学可求。先点地图上的听雨渡，踏出第一程。", 14)
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var panel: PanelContainer = PanelContainer.new()
    panel.name = "Details"
    panel.custom_minimum_size.x = 330
    body.add_child(panel)
    var right: VBoxContainer = VBoxContainer.new()
    panel.add_child(right)
    tabs = HBoxContainer.new()
    right.add_child(tabs)
    button(tabs, "地界", func() -> void: change_page("place"), "tab_place")
    button(tabs, "武学", func() -> void: change_page("arts"), "tab_arts")
    button(tabs, "行记", func() -> void: change_page("journal"), "tab_journal")
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    right.add_child(scroll)
    sidebar = VBoxContainer.new()
    sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(sidebar)
    status = label(root_box, "世界原型 · 2D 日程 / 3D 切磋 · 随身系统尚未启用", 14)
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    new_dialog = ConfirmationDialog.new()
    new_dialog.title = "开始新的旅程"
    new_dialog.dialog_text = "当前未保存的进度将离开。已有磁盘存档仍保留，直到你再次保存。"
    new_dialog.confirmed.connect(start_new)
    add_child(new_dialog)
    refresh()

func label(parent: Node, text: String, font_size: int = 16) -> Label:
    var result: Label = Label.new()
    result.text = text
    result.add_theme_font_size_override("font_size", font_size)
    parent.add_child(result)
    return result

func paragraph(text: String, font_size: int = 16) -> Label:
    var result: Label = label(sidebar, text, font_size)
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return result

func button(parent: Node, text: String, callback: Callable, id: String = "") -> Button:
    var result: Button = Button.new()
    result.text = text
    result.custom_minimum_size.y = 38
    result.pressed.connect(callback)
    parent.add_child(result)
    if not id.is_empty():
        result.name = id
        action_buttons[id] = result
    return result

func refresh() -> void:
    heading.text = "江湖初行  /  第 %d 日" % state.day
    character.text = "初始资质  根骨 %d · 悟性 %d · 魅力 %d    |    性格：%s    |    阴息 %d / 阳息 %d" % [state.aptitudes["根骨"],state.aptitudes["悟性"],state.aptitudes["魅力"],state.personality,state.yin,state.yang]
    character.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for child: Node in sidebar.get_children():
        sidebar.remove_child(child)
        child.queue_free()
    for id: String in action_buttons.keys():
        if not is_instance_valid(action_buttons[id]) or action_buttons[id].is_queued_for_deletion():
            action_buttons.erase(id)
    map_canvas.current = state.location
    map_canvas.selected = selected
    map_canvas.visited = state.visited
    map_canvas.visible = not in_battle
    viewport_box.visible = in_battle
    battle_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if in_battle else SubViewport.UPDATE_DISABLED
    for child: Node in tabs.get_children():
        (child as Button).disabled = in_battle
    for id: String in ["save", "load", "new"]:
        action_buttons[id].disabled = in_battle
    if in_battle:
        show_battle()
    elif page == "arts":
        show_arts()
    elif page == "journal":
        paragraph("行旅札记", 23)
        for index: int in range(state.journal.size()-1,-1,-1):
            paragraph(state.journal[index],14)
    else:
        show_place()

func show_place() -> void:
    var place: Dictionary = World.PLACES[selected]
    paragraph(str(place.region), 14)
    paragraph(str(place.title), 25)
    paragraph(str(place.intro).replace("\n", "
"))
    if selected != state.location:
        var reachable: bool = selected in World.PLACES[state.location].links
        var go: Button = button(sidebar, "启程前往 · 一天" if reachable else "需沿相连路线抵达", travel_selected, "travel")
        go.disabled = not reachable
        paragraph("当前位置：" + str(World.PLACES[state.location].title),14)
        return
    paragraph("「%s」
%s" % [place.teacher,place.dialogue],14)
    if place.has("manual"):
        var learned: bool = str(place.manual) in state.manuals
        var learn_button: Button = button(sidebar, "已获基础传承" if learned else "请教 · 学习基础传承", learn_here, "learn")
        learn_button.disabled = learned
    var cultivation: Button = button(sidebar, "修炼主修心法 · 一天", cultivate_here, "cultivate")
    cultivation.disabled = state.active_manual.is_empty()
    var practice_button: Button = button(sidebar, "入场切磋", enter_battle, "battle")
    practice_button.disabled = state.active_skill.is_empty()
    paragraph("下一步：沿地图前往两派求学。日常修炼不会改变初始资质。",14)

func show_arts() -> void:
    paragraph("所学武藏", 24)
    paragraph("选择主修心法与当前招数。原型中阴阳积累分别展示，数值可继续调整。",14)
    for id: String in World.MANUALS:
        var manual: Dictionary = World.MANUALS[id]
        paragraph("《%s》 · %s" % [manual.title,manual.polarity],18)
        paragraph(str(manual.intro),14)
        var choice: Button = button(sidebar, "正在主修" if id == state.active_manual else "设为主修" if id in state.manuals else "尚未获授", func() -> void: set_manual(id), "manual_"+id)
        choice.disabled = not id in state.manuals or id == state.active_manual
    for id: String in World.SKILLS:
        var art: Dictionary = World.SKILLS[id]
        paragraph(str(art.title) + " · " + str(art.polarity),18)
        paragraph(str(art.intro),14)
        var choice: Button = button(sidebar, "正在使用" if id == state.active_skill else "选用招数" if id in state.skills else "尚未学会", func() -> void: set_skill(id), "skill_"+id)
        choice.disabled = not id in state.skills or id == state.active_skill

func show_battle() -> void:
    paragraph("演武 · 第 %d 回合" % battle.turn,24)
    paragraph("你  %d / 100
对手  %d / 65
可用内力  %d / 4" % [battle.player_hp,battle.enemy_hp,battle.energy],18)
    if battle.finished:
        paragraph("切磋获胜" if battle.won else "切磋落败",24)
        paragraph("所学与修炼不会丢失。回到江湖，继续求学。",14)
        var leave: Button = button(sidebar,"返回大地图",leave_battle,"leave_battle")
        leave.disabled = stage.busy
        return
    paragraph("对手下回合：" + ("重掌蓄势" if battle.turn % 2 == 0 else "试探进攻"),16)
    paragraph("对手出言挑衅 · 刚烈触发激愤
本回合攻势更强，守势降低。" if battle.turn % 3 == 0 else "心境平稳 · 无临时状态",14)
    var basic: Button = button(sidebar,"普通出手 · 回复 1 内力",func() -> void: battle_action("basic"),"basic")
    var skill: Button = button(sidebar,str(World.SKILLS[state.active_skill].title)+" · 消耗 2 内力",func() -> void: battle_action("technique"),"technique")
    var guard: Button = button(sidebar,"守势调息 · 回复 2 内力",func() -> void: battle_action("guard"),"guard")
    basic.disabled = stage.busy
    skill.disabled = stage.busy or battle.energy < 2
    guard.disabled = stage.busy
    var retreat: Button = button(sidebar,"结束切磋",leave_battle,"retreat")
    retreat.disabled = stage.busy
    paragraph("切磋回合不消耗日程。出招镜头为原型演出，资质保持不变。",14)

func select_place(destination: String) -> void:
    if in_battle:
        return
    selected = destination
    page = "place"
    refresh()

func change_page(value: String) -> void:
    page = value
    refresh()

func travel_selected() -> void:
    if state.travel(selected):
        status.text = "抵达" + str(World.PLACES[selected].title) + "。此行用去一天。"
    refresh()

func learn_here() -> void:
    if state.learn():
        status.text = "获授心法与招数。可以修炼一天，再进入练武场试试。"
    refresh()

func cultivate_here() -> void:
    if state.cultivate():
        status.text = "一日修炼已毕。内息增长，根骨、悟性、魅力不变。"
    refresh()

func set_manual(id: String) -> void:
    state.choose_manual(id)
    refresh()

func set_skill(id: String) -> void:
    state.equip(id)
    refresh()

func enter_battle() -> void:
    if state.active_skill.is_empty():
        return
    battle.begin(state)
    in_battle = true
    status.text = "切磋开始。观察对手意图，选择出招或调息。"
    refresh()

func battle_action(action: String) -> void:
    if stage.busy:
        return
    var result: Dictionary = battle.act(action)
    if result.is_empty():
        return
    stage.play_action(result)
    status.text = "%s · 造成 %d 点伤害，受到 %d 点伤害。" % [result.mood,result.damage,result.incoming]
    refresh()

func _battle_animation_finished() -> void:
    refresh()

func leave_battle() -> void:
    if stage.busy:
        return
    if battle.finished:
        state.note("切磋获胜。" if battle.won else "切磋落败，记下心得。")
    in_battle = false
    page = "place"
    status.text = "回到江湖。切磋状态已结束。"
    refresh()

func save_game() -> void:
    var result: Error = Store.save_state(state)
    status.text = "旅程已保存到本机。" if result == OK else "保存失败；如曾成功保存，可尝试读档恢复上一份备份。错误：" + str(result)

func load_game() -> void:
    var result: Error = Store.load_state(state)
    if result == OK:
        selected = state.location
        page = "place"
        status.text = "主存档异常，已恢复上一份备份；原文件未改动。" if Store.recovered_backup else "已读回保存的旅程。"
        refresh()
    else:
        status.text = "还没有存档，请先保存。" if result == ERR_FILE_NOT_FOUND else "存档无法读取；当前旅程与原文件均保留。"

func request_new() -> void:
    new_dialog.popup_centered(Vector2i(500,180))

func start_new() -> void:
    state = Rules.new()
    selected = "town"
    page = "place"
    status.text = "新的旅程从临江镇开始。旧存档尚未覆盖。"
    refresh()
