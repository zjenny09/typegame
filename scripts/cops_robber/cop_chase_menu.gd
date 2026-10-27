extends Control
## 警察抓小偷：关卡选择页（第 1 关字母 / 第 2 关单词）。

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

	var letter_btn := _level_button("第 1 关 · 字母", 1, Vector2(220, 330))
	_add_desc("小偷每 2.4 秒跑一步 · 快打就能追上", Vector2(220, 500))
	var word_btn := _level_button("第 2 关 · 单词", 2, Vector2(680, 330))
	_add_desc("外研社三年级词汇 · 小偷每 7 秒跑一步", Vector2(680, 500))

	var back := Button.new()
	back.text = "返回"
	back.position = Vector2(24, 20)
	back.size = Vector2(120, 48)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(START_MENU_SCENE))
	add_child(back)


func _add_desc(text: String, pos: Vector2) -> void:
	var desc := Label.new()
	desc.text = text
	desc.position = pos
	desc.size = Vector2(380, 30)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98, 0.95))
	add_child(desc)


func _level_button(text: String, level: int, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(380, 160)
	btn.add_theme_font_size_override("font_size", 42)
	btn.pressed.connect(func() -> void:
		GameSession.cop_level = level
		get_tree().change_scene_to_file(COP_GAME_SCENE))
	add_child(btn)
	return btn


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 300), Color(0.78, 0.88, 0.96))
	draw_circle(Vector2(1120, 74), 42, Color(1.0, 0.9, 0.55, 0.95))
	for i in 8:
		var bx := 40.0 + i * 170.0
		var bh := 110.0 + (i % 3) * 44.0
		draw_rect(Rect2(bx, 300 - bh, 120, bh), Color(0.58, 0.68, 0.78))
		for r in int(bh / 40.0):
			for c in 2:
				draw_rect(Rect2(bx + 22 + c * 48, 300 - bh + 16 + r * 38, 22, 20),
					Color(1, 1, 1, 0.5))
	draw_rect(Rect2(0, 300, 1280, 420), Color(0.3, 0.32, 0.36))
	for i in 10:
		draw_rect(Rect2(30.0 + i * 130.0, 500, 60, 8), Color(0.9, 0.85, 0.5, 0.8))


func _draw_cloud(center: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	for data in [[0.0, 0.0, 34.0], [-30.0, 8.0, 24.0], [30.0, 8.0, 24.0]]:
		draw_circle(center + Vector2(data[0] * s, data[1] * s), data[2] * s, col)
