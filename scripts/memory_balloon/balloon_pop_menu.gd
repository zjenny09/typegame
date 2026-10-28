extends Control
## 记忆气球：关卡选择页（第 1 关字母 / 第 2 关单词）。
## 全键盘操作：A/D、方向键切换关卡，回车进入，Esc 返回主菜单。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const BALLOON_GAME_SCENE := "res://scenes/memory_balloon/balloon_pop.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_ui()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "记忆气球"
	title.position = Vector2(0, 84)
	title.size = Vector2(1280, 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "气球上的字母几秒后就会淡出——记住它，把它打爆成满天烟花！"
	subtitle.position = Vector2(0, 172)
	subtitle.size = Vector2(1280, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
	add_child(subtitle)

	var diff_row := MenuButtonRow.new()
	diff_row.position = Vector2(415, 246)
	diff_row.add_theme_constant_override("separation", 24)
	diff_row.sel = GameSession.difficulty
	diff_row.setup([
		{"text": "轻松", "min_size": Vector2(150, 52), "font_size": 26,
			"action": func() -> void: GameSession.difficulty = GameSession.Difficulty.EASY},
		{"text": "标准", "min_size": Vector2(150, 52), "font_size": 26,
			"action": func() -> void: GameSession.difficulty = GameSession.Difficulty.NORMAL},
		{"text": "挑战", "min_size": Vector2(150, 52), "font_size": 26,
			"action": func() -> void: GameSession.difficulty = GameSession.Difficulty.HARD},
	])
	add_child(diff_row)

	var row := MenuButtonRow.new()
	row.position = Vector2(220, 330)
	row.add_theme_constant_override("separation", 80)
	row.setup([
		{
			"text": "第 1 关 · 字母",
			"min_size": Vector2(380, 160),
			"font_size": 42,
			"action": func() -> void: _start_level(1),
		},
		{
			"text": "第 2 关 · 单词",
			"min_size": Vector2(380, 160),
			"font_size": 42,
			"action": func() -> void: _start_level(2),
		},
	])
	add_child(row)

	_add_desc("文字看到半程 · 炸 20 个获胜", Vector2(220, 500))
	_add_desc("基础英语词汇 · 文字看到半程 · 炸 12 个获胜", Vector2(680, 500))
	_add_best("balloon", 1, Vector2(220, 532))
	_add_best("balloon", 2, Vector2(680, 532))

	var back := Button.new()
	back.text = "返回"
	back.position = Vector2(24, 20)
	back.size = Vector2(120, 48)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(START_MENU_SCENE))
	add_child(back)

	var hint := Label.new()
	hint.text = "A / D 或方向键选关 · 回车进入 · Esc 返回"
	hint.position = Vector2(0, 660)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
	add_child(hint)


func _add_desc(text: String, pos: Vector2) -> void:
	var desc := Label.new()
	desc.text = text
	desc.position = pos
	desc.size = Vector2(380, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
	add_child(desc)


func _add_best(game_id: String, level: int, pos: Vector2) -> void:
	var b := SaveStore.best(game_id, GameSession.difficulty, level)
	if b.is_empty():
		return
	var label := Label.new()
	label.text = "最佳 %d 星 · %d 秒" % [int(b.get("stars", 0)), int(b.get("time", 0))]
	label.position = pos
	label.size = Vector2(380, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	add_child(label)


func _start_level(level: int) -> void:
	GameSession.balloon_level = level
	get_tree().change_scene_to_file(BALLOON_GAME_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(START_MENU_SCENE)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.12, 0.16, 0.28))
	# 星星
	for i in 40:
		var sx := (i * 197.3)
		sx -= floor(sx / 1280.0) * 1280.0
		var sy := (i * 131.7)
		sy -= floor(sy / 420.0) * 420.0
		draw_circle(Vector2(sx + 14.0, sy + 20.0), 1.6 + (i % 3) * 0.7,
			Color(1, 1, 1, 0.35 + 0.3 * float(i % 3)))
	draw_circle(Vector2(1110, 96), 42, Color(0.93, 0.93, 0.82, 0.95))
	# 山与地面剪影
	var hills := PackedVector2Array([
		Vector2(0, 720), Vector2(0, 620), Vector2(240, 540),
		Vector2(520, 630), Vector2(760, 550), Vector2(1040, 640), Vector2(1280, 580),
		Vector2(1280, 720),
	])
	draw_colored_polygon(hills, Color(0.07, 0.09, 0.16))
	draw_rect(Rect2(0, 660, 1280, 60), Color(0.07, 0.09, 0.16))
	# 示例气球
	_draw_demo_balloon(Vector2(180, 430), Color(0.9, 0.48, 0.58))
	_draw_demo_balloon(Vector2(1090, 380), Color(0.55, 0.75, 0.95))


func _draw_demo_balloon(pos: Vector2, col: Color) -> void:
	draw_line(pos + Vector2(0, 52), pos + Vector2(10, 130), Color(0.5, 0.52, 0.6, 0.7), 2.0)
	var pts := PackedVector2Array([
		pos + Vector2(-7, 44), pos + Vector2(7, 44), pos + Vector2(0, 36),
	])
	draw_colored_polygon(pts, col)
	draw_set_transform(pos, 0.0, Vector2(1.0, 1.18))
	draw_circle(Vector2.ZERO, 38, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(pos + Vector2(-12, -14), 10, Color(1, 1, 1, 0.7))
