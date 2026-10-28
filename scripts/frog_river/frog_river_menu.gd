extends Control
## 小青蛙过河：关卡选择页（第 1 关字母 / 第 2 关单词）。
## 全键盘操作：A/D、方向键切换关卡，回车进入，Esc 返回主菜单。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const FROG_GAME_SCENE := "res://scenes/frog_river/frog_river.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_ui()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "小青蛙过河"
	title.position = Vector2(0, 84)
	title.size = Vector2(1280, 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.16, 0.34, 0.14))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "打对荷叶上的字母或单词，帮小青蛙按顺序跳过小河"
	subtitle.position = Vector2(0, 172)
	subtitle.size = Vector2(1280, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.5, 0.35))
	add_child(subtitle)

	var row := MenuButtonRow.new()
	row.position = Vector2(220, 330)
	row.add_theme_constant_override("separation", 80)
	row.setup([
		{
			"text": "第 1 关 · 字母",
			"min_size": Vector2(380, 160),
			"font_size": 42,
			"action": func() -> void: _start_level(GameSession.FrogLevel.LETTERS),
		},
		{
			"text": "第 2 关 · 单词",
			"min_size": Vector2(380, 160),
			"font_size": 42,
			"action": func() -> void: _start_level(GameSession.FrogLevel.WORDS),
		},
	])
	add_child(row)

	_add_desc("随机出现的 26 个英文字母", Vector2(220, 500))
	_add_desc("小学三年级英语核心词汇", Vector2(680, 500))
	_add_best("frog", GameSession.FrogLevel.LETTERS, Vector2(220, 532))
	_add_best("frog", GameSession.FrogLevel.WORDS, Vector2(680, 532))

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
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	add_child(hint)


func _add_desc(text: String, pos: Vector2) -> void:
	var desc := Label.new()
	desc.text = text
	desc.position = pos
	desc.size = Vector2(380, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.42, 0.52, 0.36))
	add_child(desc)


func _add_best(game_id: String, level: int, pos: Vector2) -> void:
	var b := SaveStore.best(game_id, level)
	if b.is_empty():
		return
	var label := Label.new()
	label.text = "最佳 %d 星 · %d 秒" % [int(b.get("stars", 0)), int(b.get("time", 0))]
	label.position = pos
	label.size = Vector2(380, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.15))
	add_child(label)


func _start_level(level: int) -> void:
	GameSession.frog_level = level
	get_tree().change_scene_to_file(FROG_GAME_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(START_MENU_SCENE)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 250), Color(0.78, 0.9, 0.98))
	draw_rect(Rect2(0, 250, 1280, 470), Color(0.62, 0.84, 0.47))
	draw_circle(Vector2(1130, 78), 44, Color(1.0, 0.9, 0.55, 0.95))
	_draw_cloud(Vector2(200, 90), 1.0)
	_draw_cloud(Vector2(480, 60), 0.7)
	for i in 6:
		var fx := 120.0 + i * 210.0
		var fy := 590.0 + (i % 3) * 30.0
		draw_circle(Vector2(fx, fy), 7, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(fx, fy), 3, Color(1, 0.85, 0.3, 0.9))


func _draw_cloud(center: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	for data in [[0.0, 0.0, 34.0], [-30.0, 8.0, 24.0], [30.0, 8.0, 24.0]]:
		draw_circle(center + Vector2(data[0] * s, data[1] * s), data[2] * s, col)
