extends Control
## 打雪球：关卡选择页（第 1 关字母 / 第 2 关单词）。
## 全键盘操作：A/D、方向键切换关卡，回车进入，Esc 返回主菜单。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const SNOW_GAME_SCENE := "res://scenes/snowball/snow_fight.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_ui()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "打雪球"
	title.position = Vector2(0, 84)
	title.size = Vector2(1280, 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.2, 0.32, 0.45))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "雪球一个接一个从天上掉下来，看准了打出上面的字母或单词把它砸碎！"
	subtitle.position = Vector2(0, 172)
	subtitle.size = Vector2(1280, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.38, 0.45, 0.55))
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

	_add_desc("雪球约 8 秒落地 · 击碎 20 个获胜", Vector2(220, 500))
	_add_desc("小学三年级词汇 · 击碎 12 个获胜", Vector2(680, 500))
	_add_best("snow", 1, Vector2(220, 532))
	_add_best("snow", 2, Vector2(680, 532))

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
	hint.add_theme_color_override("font_color", Color(0.45, 0.52, 0.62))
	add_child(hint)


func _add_desc(text: String, pos: Vector2) -> void:
	var desc := Label.new()
	desc.text = text
	desc.position = pos
	desc.size = Vector2(380, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.45, 0.52, 0.62))
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
	label.add_theme_color_override("font_color", Color(0.3, 0.4, 0.55))
	add_child(label)


func _start_level(level: int) -> void:
	GameSession.snow_level = level
	get_tree().change_scene_to_file(SNOW_GAME_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(START_MENU_SCENE)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 560), Color(0.84, 0.89, 0.94))
	draw_circle(Vector2(1110, 96), 42, Color(1.0, 0.96, 0.85, 0.9))
	_draw_mountain(260.0, 560.0, 300.0)
	_draw_mountain(900.0, 560.0, 380.0)
	draw_rect(Rect2(0, 560, 1280, 160), Color(0.96, 0.97, 1.0))
	for i in 10:
		draw_circle(Vector2(i * 140.0 + 40.0, 572.0), 30.0, Color(0.96, 0.97, 1.0))
	_draw_tree(Vector2(140, 560))
	_draw_tree(Vector2(1150, 560))


func _draw_mountain(center_x: float, base_y: float, half_w: float) -> void:
	var pts := PackedVector2Array([
		Vector2(center_x - half_w, base_y),
		Vector2(center_x, base_y - half_w * 0.9),
		Vector2(center_x + half_w, base_y),
	])
	draw_colored_polygon(pts, Color(0.94, 0.96, 0.99))


func _draw_tree(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 8, pos.y - 26, 16, 26), Color(0.4, 0.28, 0.18))
	for k in 3:
		var w := 64.0 - k * 16.0
		var top := pos.y - 30.0 - k * 40.0
		var pts := PackedVector2Array([
			Vector2(pos.x - w, top),
			Vector2(pos.x + w, top),
			Vector2(pos.x, top - 56.0),
		])
		draw_colored_polygon(pts, Color(0.22, 0.45, 0.32))
		draw_rect(Rect2(pos.x - w * 0.4, top - 6, w * 0.8, 7), Color(0.96, 0.97, 1.0))
