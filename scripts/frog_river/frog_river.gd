extends Control
## 小青蛙过河主玩法。
## 画面中间竖着一条河：小青蛙从左岸出发，荷叶从左到右排开；
## 依次打对每片荷叶上的字母（第 1 关）或单词（第 2 关），
## 打对一片跳一片，不能跨片；打错提示并重输当前荷叶，不回退、不刷新。
## 不设限时；跳到右岸显示游戏胜利。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const LATIN_FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const LATIN_FONT_TAG := "[font=res://assets/fonts/PatrickHand-Regular.ttf]"
const FROG_MENU_SCENE := "res://scenes/frog_river/frog_river_menu.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"
const GAME_ID := "frog"

const VIEW := Vector2(1280.0, 720.0)
const BANK_W := 250.0
const RIVER_LEFT := BANK_W
const RIVER_RIGHT := VIEW.x - BANK_W
const PAD_ROW_Y := 430.0
const PAD_DY := 52.0
const JUMP_DURATION := 0.5
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# 难度参数：[难度][关卡] → 荷叶数 / 单词长度上限
const LEVEL_PARAMS := {
	0: {1: {"pads": 5, "max_len": 6}, 2: {"pads": 5, "max_len": 6}},
	1: {1: {"pads": 6, "max_len": 8}, 2: {"pads": 6, "max_len": 8}},
	2: {1: {"pads": 7, "max_len": 8}, 2: {"pads": 7, "max_len": 8}},
}

enum State { PLAYING, JUMPING, WON }

var level := GameSession.FrogLevel.LETTERS
var pad_count := 6
var max_len := 8
var pad_rx := 52.0
var pads: Array = []  # {text, zh, x, y, done, flash, shake}
var next_target := 0
var typed_len := 0
var mistakes := 0
var elapsed := 0.0
var state := State.PLAYING

var frog_pos := Vector2.ZERO
var frog_scale := 1.0
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var jump_t := 0.0
var jump_is_final := false
var jump_won_after := false
var splashes: Array = []  # {pos, t}
var time_acc := 0.0
var message_until_ms := 0

var hud_level: Label
var hud_progress: Label
var hud_prompt: RichTextLabel
var hud_message: Label
var win_layer: Control
var win_stats: Label
var best_label: Label
var win_stars: StarRow


func _ready() -> void:
	level = GameSession.frog_level
	var params: Dictionary = LEVEL_PARAMS[GameSession.difficulty][level]
	pad_count = params["pads"]
	max_len = params["max_len"]
	pad_rx = minf(52.0, (RIVER_RIGHT - RIVER_LEFT) / (pad_count + 1.0) * 0.42)
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_hud()
	_build_win_layer()
	_start_level()


func _start_level() -> void:
	pads.clear()
	splashes.clear()
	typed_len = 0
	mistakes = 0
	elapsed = 0.0
	next_target = 0
	state = State.PLAYING
	frog_scale = 1.0
	if level == GameSession.FrogLevel.LETTERS:
		var pool: Array = []
		for ch in LETTERS:
			pool.append(ch)
		pool.shuffle()
		for i in pad_count:
			_add_pad(pool[i], "")
	else:
		var entries := WordBank.pick_words(pad_count, max_len)
		for i in pad_count:
			_add_pad(entries[i][0], entries[i][1])
	frog_pos = Vector2(BANK_W * 0.5, PAD_ROW_Y)
	hud_message.visible = false
	win_layer.visible = false
	_update_hud()


func _add_pad(text: String, zh: String) -> void:
	var i := pads.size()
	var x := RIVER_LEFT + (RIVER_RIGHT - RIVER_LEFT) * (float(i) + 1.0) / (float(PAD_COUNT) + 1.0)
	var y := PAD_ROW_Y + (PAD_DY if i % 2 == 1 else -PAD_DY)
	pads.append({"text": text, "zh": zh, "x": x, "y": y, "done": false, "flash": 0.0, "shake": 0.0})


func _build_hud() -> void:
	hud_level = Label.new()
	hud_level.position = Vector2(24, 14)
	hud_level.size = Vector2(520, 38)
	hud_level.add_theme_font_size_override("font_size", 30)
	hud_level.add_theme_color_override("font_color", Color(0.16, 0.34, 0.14))
	add_child(hud_level)

	hud_progress = Label.new()
	hud_progress.position = Vector2(780, 16)
	hud_progress.size = Vector2(476, 34)
	hud_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_progress.add_theme_font_size_override("font_size", 26)
	hud_progress.add_theme_color_override("font_color", Color(0.3, 0.42, 0.26))
	add_child(hud_progress)

	hud_prompt = RichTextLabel.new()
	hud_prompt.position = Vector2(0, 56)
	hud_prompt.size = Vector2(1280, 60)
	hud_prompt.bbcode_enabled = true
	hud_prompt.scroll_active = false
	hud_prompt.add_theme_font_size_override("normal_font_size", 40)
	hud_prompt.add_theme_color_override("default_color", Color(0.24, 0.3, 0.2))
	add_child(hud_prompt)

	hud_message = Label.new()
	hud_message.position = Vector2(0, 124)
	hud_message.size = Vector2(1280, 36)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.add_theme_font_size_override("font_size", 30)
	hud_message.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	hud_message.visible = false
	add_child(hud_message)

	var hint := Label.new()
	hint.text = "按键盘 A 到 Z 输入 · 打对一片跳一片 · 按 Esc 返回选关"
	hint.position = Vector2(0, 686)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.3, 0.4, 0.25, 0.85))
	add_child(hint)


func _build_win_layer() -> void:
	win_layer = Control.new()
	win_layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.18, 0.12, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = -220.0
	panel.offset_bottom = 220.0
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(1, 1, 1, 0.97)
	panel_sb.set_corner_radius_all(24)
	panel_sb.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", panel_sb)
	win_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var win_title := Label.new()
	win_title.text = "游戏胜利！"
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title.add_theme_font_size_override("font_size", 56)
	win_title.add_theme_color_override("font_color", Color(0.2, 0.55, 0.25))
	vbox.add_child(win_title)

	win_stars = StarRow.new()
	win_stars.custom_minimum_size = Vector2(300, 76)
	win_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(win_stars)

	win_stats = Label.new()
	win_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_stats.add_theme_font_size_override("font_size", 28)
	win_stats.add_theme_color_override("font_color", Color(0.35, 0.4, 0.32))
	vbox.add_child(win_stats)

	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 22)
	best_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.5))
	vbox.add_child(best_label)

	var buttons := MenuButtonRow.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	buttons.setup([
		{"text": "再玩一次", "action": func() -> void: _start_level()},
		{"text": "选关卡", "action": func() -> void: get_tree().change_scene_to_file(FROG_MENU_SCENE)},
		{"text": "主菜单", "action": func() -> void: get_tree().change_scene_to_file(START_MENU_SCENE)},
	])
	vbox.add_child(buttons)

	win_layer.visible = false
	add_child(win_layer)


func _update_hud() -> void:
	var level_name := "字母" if level == GameSession.FrogLevel.LETTERS else "单词"
	hud_level.text = "小青蛙过河 · 第 %d 关（%s）" % [level, level_name]
	hud_progress.text = "荷叶 %d / %d · 失误 %d" % [next_target, pad_count, mistakes]
	if state == State.WON:
		hud_prompt.text = "[center][color=#2e8b3a]到达对岸！[/color][/center]"
		return
	if next_target >= PAD_COUNT:
		return
	var pad: Dictionary = pads[next_target]
	var target: String = pad["text"]
	var typed_part := target.substr(0, typed_len)
	var rest := target.substr(typed_len)
	var line := "[center]请输入：%s[color=#2e8b3a]%s[/color][/font]%s%s[/font]" % [
		LATIN_FONT_TAG, typed_part, LATIN_FONT_TAG, rest,
	]
	if level == GameSession.FrogLevel.WORDS and (pad["zh"] as String) != "":
		line += "　（%s）" % pad["zh"]
	hud_prompt.text = line + "[/center]"


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(FROG_MENU_SCENE)
		return
	if state != State.PLAYING:
		return
	var k: int = event.keycode
	if k < KEY_A or k > KEY_Z:
		return
	_handle_char(char(65 + (k - KEY_A)))


func _handle_char(c: String) -> void:
	var pad: Dictionary = pads[next_target]
	var target: String = pad["text"]
	var expected: String = target[typed_len]
	if expected.to_lower() == c.to_lower():
		typed_len += 1
		hud_message.visible = false
		Sfx.play("type")
		if typed_len >= target.length():
			typed_len = 0
			pad["done"] = true
			Sfx.play("splash")
			_update_hud()
			_start_jump(Vector2(pad["x"], pad["y"]), next_target == pad_count - 1)
		else:
			_update_hud()
	else:
		mistakes += 1
		typed_len = 0
		pad["flash"] = 0.7
		pad["shake"] = 0.5
		Sfx.play("wrong")
		var hint_text := "打错啦！重新输入「%s」" % target
		if level == GameSession.FrogLevel.WORDS and (pad["zh"] as String) != "":
			hint_text += "（%s）" % pad["zh"]
		_show_message(hint_text)
		_update_hud()


func _show_message(text: String) -> void:
	hud_message.text = text
	hud_message.visible = true
	message_until_ms = Time.get_ticks_msec() + 1800


func _start_jump(to: Vector2, is_last_pad: bool) -> void:
	state = State.JUMPING
	jump_from = frog_pos
	jump_to = to
	jump_t = 0.0
	jump_is_final = is_last_pad
	jump_won_after = false


func _process(delta: float) -> void:
	var d := minf(delta, 0.1)
	time_acc += d
	if state == State.PLAYING:
		elapsed += d
	for pad in pads:
		if pad["flash"] > 0.0:
			pad["flash"] = maxf(0.0, pad["flash"] - d)
		if pad["shake"] > 0.0:
			pad["shake"] = maxf(0.0, pad["shake"] - d)
	if hud_message.visible and Time.get_ticks_msec() > message_until_ms:
		hud_message.visible = false
	for i in range(splashes.size() - 1, -1, -1):
		splashes[i]["t"] += d
		if splashes[i]["t"] > 0.6:
			splashes.remove_at(i)
	if state == State.JUMPING:
		jump_t += d / JUMP_DURATION
		var t := minf(jump_t, 1.0)
		frog_pos = jump_from.lerp(jump_to, t)
		frog_scale = 1.0 + 0.35 * sin(PI * t)
		if jump_t >= 1.0:
			frog_scale = 1.0
			if jump_to.x > RIVER_LEFT and jump_to.x < RIVER_RIGHT:
				splashes.append({"pos": frog_pos, "t": 0.0})
			if jump_won_after:
				state = State.WON
				_show_win()
			elif jump_is_final:
				jump_from = frog_pos
				jump_to = Vector2(VIEW.x - BANK_W * 0.5, PAD_ROW_Y)
				jump_t = 0.0
				jump_is_final = false
				jump_won_after = true
			else:
				next_target += 1
				state = State.PLAYING
				_update_hud()
	queue_redraw()


func _star_count() -> int:
	return 3 if mistakes == 0 else (2 if mistakes <= 2 else 1)


func _show_win() -> void:
	win_layer.visible = true
	win_stars.count = _star_count()
	SaveStore.record_result(GAME_ID, GameSession.difficulty, level, win_stars.count, int(elapsed), mistakes)
	win_stats.text = "用时 %d 秒 · 失误 %d 次" % [int(elapsed), mistakes]
	var b := SaveStore.best(GAME_ID, GameSession.difficulty, level)
	if b.is_empty():
		best_label.text = ""
	else:
		best_label.text = "历史最佳：%d 秒 · %d 星" % [int(b.get("time", 0)), int(b.get("stars", 0))]
	hud_message.visible = false
	_update_hud()


func _draw() -> void:
	_draw_scenery()
	_draw_pads()
	_draw_splashes()
	_draw_frog()


func _draw_scenery() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, 140), Color(0.78, 0.9, 0.98))
	draw_circle(Vector2(1150, 70), 42, Color(1.0, 0.88, 0.5, 0.95))
	_draw_cloud(Vector2(150, 66), 0.9)
	draw_rect(Rect2(0, 140, RIVER_LEFT, VIEW.y - 140), Color(0.62, 0.84, 0.47))
	draw_rect(Rect2(RIVER_RIGHT, 140, VIEW.x - RIVER_RIGHT, VIEW.y - 140), Color(0.62, 0.84, 0.47))
	draw_rect(Rect2(RIVER_LEFT - 14, 140, 14, VIEW.y - 140), Color(0.5, 0.72, 0.38))
	draw_rect(Rect2(RIVER_RIGHT, 140, 14, VIEW.y - 140), Color(0.5, 0.72, 0.38))
	for i in 8:
		var fx := 60.0 + i * 175.0
		if fx > RIVER_LEFT - 30.0 and fx < RIVER_RIGHT + 30.0:
			continue
		var fy := 210.0 + (i * 137) % 440
		draw_circle(Vector2(fx, fy), 7, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(fx, fy), 3, Color(1, 0.85, 0.3, 0.9))
	# 河
	draw_rect(Rect2(RIVER_LEFT, 140, RIVER_RIGHT - RIVER_LEFT, VIEW.y - 140), Color(0.37, 0.69, 0.91))
	var river_w := RIVER_RIGHT - RIVER_LEFT - 48.0
	for i in 12:
		var phase := time_acc * 26.0
		var wx := RIVER_LEFT + 24.0 + fposmod(i * 101.7 + phase, river_w)
		var wy := 190.0 + (i * 97) % 490
		draw_arc(Vector2(wx, wy), 16, PI * 1.15, PI * 1.85, 10, Color(1, 1, 1, 0.4), 3)


func _draw_cloud(center: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	for data in [[0.0, 0.0, 34.0], [-30.0, 8.0, 24.0], [30.0, 8.0, 24.0]]:
		draw_circle(center + Vector2(data[0] * s, data[1] * s), data[2] * s, col)


func _draw_pads() -> void:
	for i in pads.size():
		var pad: Dictionary = pads[i]
		var pos := Vector2(pad["x"], pad["y"])
		var done: bool = pad["done"]
		var is_current: bool = i == next_target and state != State.WON
		if is_current:
			var halo_r := pad_rx * 1.21 + sin(time_acc * 5.0) * 5.0
			draw_arc(pos, halo_r, 0, TAU, 40, Color(1.0, 0.83, 0.2, 0.85), 5)
		var f := pad_rx / 52.0
		_draw_ellipse(pos + Vector2(0, 4 * f), 56 * f, 33 * f, Color(0.16, 0.42, 0.2))
		_draw_ellipse(pos, 53 * f, 30 * f, Color(0.45, 0.75, 0.42) if done else Color(0.27, 0.63, 0.29))
		_draw_ellipse(pos + Vector2(-8 * f, -6 * f), 38 * f, 19 * f, Color(0.37, 0.72, 0.36, 0.9))
		var pts := PackedVector2Array([pos])
		for a in [-0.05, 0.4]:
			pts.push_back(pos + Vector2(cos(a) * 58 * f, sin(a) * 34 * f))
		draw_colored_polygon(pts, Color(0.37, 0.69, 0.91))
		var flash: float = pad["flash"]
		if flash > 0.0:
			_draw_ellipse(pos, 53, 30, Color(0.9, 0.25, 0.2, flash * 0.45))
		_draw_sign(i, pad, pos)


func _draw_sign(i: int, pad: Dictionary, pos: Vector2) -> void:
	var text: String = pad["text"]
	var shake: float = pad["shake"]
	var off_x := sin((0.5 - shake) * 44.0) * 7.0 * shake if shake > 0.0 else 0.0
	var font_size := 34 if level == GameSession.FrogLevel.LETTERS else 27
	var tw := LATIN_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var sign_size := Vector2(tw + 34, 48)
	var sign_pos := Vector2(pos.x - sign_size.x * 0.5 + off_x, pos.y - 88.0 - sign_size.y)

	var is_current: bool = next_target == i and state != State.WON
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3)
	if pad["done"]:
		sb.bg_color = Color(0.9, 0.96, 0.87)
		sb.border_color = Color(0.44, 0.68, 0.29)
	elif is_current:
		sb.border_color = Color(0.85, 0.3, 0.25) if pad["flash"] > 0.0 else Color(0.95, 0.69, 0.21)
		sb.bg_color = Color(0.99, 0.9, 0.88) if pad["flash"] > 0.0 else Color(1.0, 0.97, 0.88)
	else:
		sb.bg_color = Color(1, 1, 1, 0.92)
		sb.border_color = Color(0.78, 0.83, 0.72)
	draw_style_box(sb, Rect2(sign_pos, sign_size))
	draw_line(Vector2(pos.x, sign_pos.y + sign_size.y), Vector2(pos.x, pos.y - 34.0),
		Color(0.78, 0.83, 0.72), 2.0)

	var base_y := sign_pos.y + sign_size.y * 0.5 + font_size * 0.36
	var text_color := Color(0.85, 0.3, 0.25) if pad["flash"] > 0.0 else Color(0.24, 0.3, 0.2)
	var typed_part := text.substr(0, typed_len if is_current else 0)
	if typed_part != "":
		var w1 := LATIN_FONT.get_string_size(typed_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(LATIN_FONT, Vector2(sign_pos.x + 17, base_y), typed_part,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.18, 0.55, 0.23))
		draw_string(LATIN_FONT, Vector2(sign_pos.x + 17 + w1, base_y), text.substr(typed_len),
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	else:
		draw_string(LATIN_FONT, Vector2(sign_pos.x + 17, base_y), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _draw_splashes() -> void:
	for splash in splashes:
		var t: float = splash["t"]
		var k := t / 0.6
		var center: Vector2 = splash["pos"]
		draw_arc(center, 10 + k * 80, 0, TAU, 26, Color(1, 1, 1, 0.55 * (1.0 - k)), 3)


func _draw_frog() -> void:
	var pos := frog_pos
	var s := frog_scale
	_draw_ellipse(pos + Vector2(0, 26 * s), 34 * s, 12 * s, Color(0.1, 0.25, 0.12, 0.2))
	_draw_ellipse(pos + Vector2(-26 * s, 14 * s), 12 * s, 8 * s, Color(0.29, 0.58, 0.26))
	_draw_ellipse(pos + Vector2(26 * s, 14 * s), 12 * s, 8 * s, Color(0.29, 0.58, 0.26))
	_draw_ellipse(pos, 36 * s, 28 * s, Color(0.35, 0.69, 0.3))
	_draw_ellipse(pos + Vector2(0, 9 * s), 22 * s, 15 * s, Color(0.63, 0.85, 0.52))
	for off in [-15.0, 15.0]:
		draw_circle(pos + Vector2(off * s, -24 * s), 11 * s, Color(0.35, 0.69, 0.3))
		draw_circle(pos + Vector2(off * s, -25 * s), 8 * s, Color(1, 1, 1))
		draw_circle(pos + Vector2(off * s, -26 * s), 4 * s, Color(0.15, 0.2, 0.12))
	draw_arc(pos, 11 * s, 0.4, PI - 0.4, 10, Color(0.19, 0.42, 0.16), 2.5)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, ry / maxf(rx, 0.001)))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
