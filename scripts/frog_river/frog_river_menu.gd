extends Control
## 小青蛙过河：关卡选择页（第 1 关字母 / 第 2 关单词）。

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

	var letter_btn := _level_button("第 1 关 · 字母", GameSession.FrogLevel.LETTERS, Vector2(220, 330))
	var letter_desc := Label.new()
	letter_desc.text = "随机出现的 26 个英文字母"
	letter_desc.position = Vector2(220, 500)
	letter_desc.size = Vector2(380, 30)
	letter_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_desc.add_theme_font_size_override("font_size", 24)
	letter_desc.add_theme_color_override("font_color", Color(0.42, 0.52, 0.36))
	add_child(letter_desc)

	var word_btn := _level_button("第 2 关 · 单词", GameSession.FrogLevel.WORDS, Vector2(680, 330))
	var word_desc := Label.new()
	word_desc.text = "外研社三年级英语词汇"
	word_desc.position = Vector2(680, 500)
	word_desc.size = Vector2(380, 30)
	word_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_desc.add_theme_font_size_override("font_size", 24)
	word_desc.add_theme_color_override("font_color", Color(0.42, 0.52, 0.36))
	add_child(word_desc)

	var back := Button.new()
	back.text = "返回"
	back.position = Vector2(24, 20)
	back.size = Vector2(120, 48)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(START_MENU_SCENE))
	add_child(back)


func _level_button(text: String, level: int, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(380, 160)
	btn.add_theme_font_size_override("font_size", 42)
	btn.pressed.connect(func() -> void:
		GameSession.frog_level = level
		get_tree().change_scene_to_file(FROG_GAME_SCENE))
	add_child(btn)
	return btn


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
