extends Control
## 警察抓小偷：关卡选择页（第 1 关字母 / 第 2 关单词）。
## 全键盘操作：A/D、方向键切换关卡，回车进入，Esc 返回主菜单。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const COP_GAME_SCENE := "res://scenes/cops_robber/cop_chase.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_ui()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "警察抓小偷"
	title.position = Vector2(0, 84)
	title.size = Vector2(1280, 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.16, 0.28, 0.42))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "小偷匀速逃跑，每跑一步留下一块牌子；打对目标警察就追一步，追上他！"
	subtitle.position = Vector2(0, 172)
	subtitle.size = Vector2(1280, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.46, 0.52))
	add_child(subtitle)

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

	_add_desc("小偷每 2.4 秒跑一步 · 快打就能追上", Vector2(220, 500))
	_add_desc("小学三年级词汇 · 小偷每 7 秒跑一步", Vector2(680, 500))

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
	desc.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98, 0.95))
	add_child(desc)


func _start_level(level: int) -> void:
	GameSession.cop_level = level
	get_tree().change_scene_to_file(COP_GAME_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(START_MENU_SCENE)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 300), Color(0.78, 0.88, 0.96))
	draw_rect(Rect2(0, 300, 1280, 420), Color(0.3, 0.32, 0.36))
	draw_circle(Vector2(1130, 78), 44, Color(1.0, 0.9, 0.55, 0.95))
	for i in 8:
		var bx := 40.0 + i * 170.0
		var bh := 110.0 + (i % 3) * 44.0
		draw_rect(Rect2(bx, 300 - bh, 120, bh), Color(0.58, 0.68, 0.78))
		for r in int(bh / 40.0):
			for c in 2:
				draw_rect(Rect2(bx + 22 + c * 48, 300 - bh + 16 + r * 38, 22, 20),
					Color(1, 1, 1, 0.5))
	for i in 10:
		draw_rect(Rect2(30.0 + i * 130.0, 500, 60, 8), Color(0.9, 0.85, 0.5, 0.8))
