extends Control
## 警察抓小偷主玩法。
## 小偷沿马路匀速逃跑，每跑一步在路上留下一块字母/单词牌；
## 从左到右依次打对目标，警察向前追一步；
## 追上小偷即胜利（打字快可以提前追上），小偷跑到逃脱点则失败。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const LATIN_FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const LATIN_FONT_TAG := "[font=res://assets/fonts/PatrickHand-Regular.ttf]"
const COP_MENU_SCENE := "res://scenes/cops_robber/cop_chase_menu.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"
const GAME_ID := "cop"

const VIEW := Vector2(1280.0, 720.0)
const SPACING := 150.0            # 每步的世界像素距离
const ROAD_TOP := 440.0
const ROAD_BOTTOM := 720.0

# 关卡参数：[难度][关卡] → 小偷一步用时（秒）/ 警察起始落后步数 / 逃脱点步数
const LEVEL_PARAMS := {
	0: {
		1: {"step_time": 3.0, "gap": 5, "track": 18},
		2: {"step_time": 8.0, "gap": 3, "track": 9},
	},
	1: {
		1: {"step_time": 2.4, "gap": 3, "track": 22},
		2: {"step_time": 7.0, "gap": 2, "track": 11},
	},
	2: {
		1: {"step_time": 1.9, "gap": 2, "track": 26},
		2: {"step_time": 5.5, "gap": 2, "track": 13},
	},
}

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

enum State { PLAYING, WON, LOST }

var level := 1
var step_time := 2.4
var gap_steps := 3
var track_len := 22

var targets: Array = []  # {text, zh, done, flash}
var next_target := 0
var typed_len := 0
var mistakes := 0
var elapsed := 0.0

var police_steps := 0.0
var thief_steps := 0.0
var step_timer := 0.0
var police_from := 0.0
var police_anim_t := 1.0
var prev_letter := ""
var word_pool: Array = []
var cam_x := 0.0
var time_acc := 0.0
var message_until_ms := 0
var state := State.PLAYING

var hud_level: Label
var hud_progress: Label
var hud_prompt: RichTextLabel
var hud_message: Label
var result_layer: Control
var result_title: Label
var result_stats: Label
var best_label: Label
var result_stars: StarRow


func _ready() -> void:
	level = GameSession.cop_level
	var params: Dictionary = LEVEL_PARAMS[GameSession.difficulty][level]
	step_time = params["step_time"]
	gap_steps = params["gap"]
	track_len = params["track"]
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_hud()
	_build_result_layer()
	_start_level()


func _start_level() -> void:
	targets.clear()
	word_pool.clear()
	next_target = 0
	typed_len = 0
	mistakes = 0
	elapsed = 0.0
	police_steps = 0.0
	thief_steps = 0.0
	police_from = 0.0
	police_anim_t = 1.0
	step_timer = 0.0
	prev_letter = ""
	state = State.PLAYING
	if level == 2:
		word_pool = WordBank.pick_words(track_len + gap_steps)
	for i in gap_steps:
		_thief_step()
	cam_x = _cam_target()
	hud_message.visible = false
	result_layer.visible = false
	_update_hud()


func _thief_step() -> void:
	thief_steps += 1.0
	var text := ""
	var zh := ""
	if level == 1:
		text = _rand_letter()
	else:
		var entry: Array = word_pool.pop_back()
		text = entry[0]
		zh = entry[1]
	targets.append({"text": text, "zh": zh, "done": false, "flash": 0.0})


func _rand_letter() -> String:
	var ch := LETTERS[randi() % 26]
	while ch == prev_letter:
		ch = LETTERS[randi() % 26]
	prev_letter = ch
	return ch


func _cam_target() -> float:
	# 镜头永远跟着警察：当前目标牌总在警察脚边可见；
	# 警察偏屏幕左 1/3，右侧留出前方道路，差距不大时小偷同框。
	var world_w := track_len * SPACING + 320.0
	return clampf(police_steps * SPACING - 420.0, 0.0, maxf(0.0, world_w - VIEW.x))


func _build_hud() -> void:
	hud_level = Label.new()
	hud_level.position = Vector2(24, 10)
	hud_level.size = Vector2(520, 38)
	hud_level.add_theme_font_size_override("font_size", 30)
	hud_level.add_theme_color_override("font_color", Color(0.16, 0.26, 0.4))
	add_child(hud_level)

	hud_progress = Label.new()
	hud_progress.position = Vector2(700, 36)
	hud_progress.size = Vector2(556, 32)
	hud_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_progress.add_theme_font_size_override("font_size", 26)
	hud_progress.add_theme_color_override("font_color", Color(0.3, 0.36, 0.44))
	add_child(hud_progress)

	hud_prompt = RichTextLabel.new()
	hud_prompt.position = Vector2(0, 66)
	hud_prompt.size = Vector2(1280, 60)
	hud_prompt.bbcode_enabled = true
	hud_prompt.scroll_active = false
	hud_prompt.add_theme_font_size_override("normal_font_size", 40)
	hud_prompt.add_theme_color_override("default_color", Color(0.24, 0.28, 0.34))
	add_child(hud_prompt)

	hud_message = Label.new()
	hud_message.position = Vector2(0, 132)
	hud_message.size = Vector2(1280, 36)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.add_theme_font_size_override("font_size", 30)
	hud_message.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	hud_message.visible = false
	add_child(hud_message)

	var hint := Label.new()
	hint.text = "按键盘 A 到 Z 输入 · 打对一个追一步 · 按 Esc 返回选关"
	hint.position = Vector2(0, 686)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 0.85))
	add_child(hint)


func _build_result_layer() -> void:
	result_layer = Control.new()
	result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.12, 0.18, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(dim)

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
	result_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	result_title = Label.new()
	result_title.text = "抓到小偷啦！"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 56)
	result_title.add_theme_color_override("font_color", Color(0.2, 0.55, 0.25))
	vbox.add_child(result_title)

	result_stars = StarRow.new()
	result_stars.custom_minimum_size = Vector2(300, 76)
	result_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(result_stars)

	result_stats = Label.new()
	result_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stats.add_theme_font_size_override("font_size", 28)
	result_stats.add_theme_color_override("font_color", Color(0.35, 0.4, 0.32))
	vbox.add_child(result_stats)

	best_label = Label.new()
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 22)
	best_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.5))
	vbox.add_child(best_label)

	var buttons := MenuButtonRow.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	buttons.setup([
		{"text": "再来一次", "action": func() -> void: _start_level()},
		{"text": "选关卡", "action": func() -> void: get_tree().change_scene_to_file(COP_MENU_SCENE)},
		{"text": "主菜单", "action": func() -> void: get_tree().change_scene_to_file(START_MENU_SCENE)},
	])
	vbox.add_child(buttons)

	result_layer.visible = false
	add_child(result_layer)


func _level_name() -> String:
	return "字母" if level == 1 else "单词"


func _update_hud() -> void:
	hud_level.text = "警察抓小偷 · 第 %d 关（%s）" % [level, _level_name()]
	var gap := maxi(0, ceili(thief_steps - police_steps))
	if state == State.PLAYING:
		hud_progress.text = "小偷 %d / %d 步 · 差距 %d 步 · 失误 %d" % [
			int(thief_steps), track_len, gap, mistakes,
		]
	else:
		hud_progress.text = "失误 %d" % mistakes
	if state == State.WON:
		hud_prompt.text = "[center][color=#2e8b3a]追上小偷啦！[/color][/center]"
		return
	if state == State.LOST:
		hud_prompt.text = "[center][color=#c0392b]小偷逃进逃脱点了！[/color][/center]"
		return
	if next_target >= targets.size():
		return
	var target: Dictionary = targets[next_target]
	var text: String = target["text"]
	var typed_part := text.substr(0, typed_len)
	var rest := text.substr(typed_len)
	var line := "[center]请输入：%s[color=#2e8b3a]%s[/color][/font]%s%s[/font]" % [
		LATIN_FONT_TAG, typed_part, LATIN_FONT_TAG, rest,
	]
	if level == 2 and (target["zh"] as String) != "":
		line += "　（%s）" % target["zh"]
	hud_prompt.text = line + "[/center]"


func _show_message(text: String) -> void:
	hud_message.text = text
	hud_message.visible = true
	message_until_ms = Time.get_ticks_msec() + 1800


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(COP_MENU_SCENE)
		return
	if state != State.PLAYING:
		return
	var k: int = event.keycode
	if k < KEY_A or k > KEY_Z:
		return
	_handle_char(char(65 + (k - KEY_A)))


func _handle_char(c: String) -> void:
	var target: Dictionary = targets[next_target]
	var text: String = target["text"]
	var expected: String = text[typed_len]
	if expected.to_lower() == c.to_lower():
		typed_len += 1
		hud_message.visible = false
		Sfx.play("type")
		if typed_len >= text.length():
			typed_len = 0
			target["done"] = true
			next_target += 1
			police_from = police_steps
			police_steps += 1.0
			police_anim_t = 0.0
			Sfx.play("step")
			_update_hud()
			if police_steps >= thief_steps - 0.0001:
				state = State.WON
				_show_result(true)
		else:
			_update_hud()
	else:
		mistakes += 1
		typed_len = 0
		target["flash"] = 0.7
		Sfx.play("wrong")
		var hint_text := "打错啦！重新输入「%s」" % text
		if level == 2 and (target["zh"] as String) != "":
			hint_text += "（%s）" % target["zh"]
		_show_message(hint_text)
		_update_hud()


func _star_count() -> int:
	return 3 if mistakes == 0 else (2 if mistakes <= 2 else 1)


func _show_result(win: bool) -> void:
	result_layer.visible = true
	Sfx.play("win" if win else "lose")
	if win:
		result_title.text = "抓到小偷啦！"
		result_title.add_theme_color_override("font_color", Color(0.2, 0.55, 0.25))
		result_stars.count = _star_count()
		SaveStore.record_result(GAME_ID, GameSession.difficulty, level, result_stars.count, int(elapsed), mistakes)
		result_stats.text = "用时 %d 秒 · 失误 %d 次" % [int(elapsed), mistakes]
	else:
		result_title.text = "小偷跑掉了…"
		result_title.add_theme_color_override("font_color", Color(0.75, 0.25, 0.2))
		result_stars.count = 0
		result_stats.text = "差 %d 步就追上了，再试一次吧！" % maxi(1, ceili(thief_steps - police_steps))
	var b := SaveStore.best(GAME_ID, GameSession.difficulty, level)
	if b.is_empty():
		best_label.text = ""
	else:
		best_label.text = "历史最佳：%d 秒 · %d 星" % [int(b.get("time", 0)), int(b.get("stars", 0))]
	hud_message.visible = false
	_update_hud()


func _process(delta: float) -> void:
	var d := minf(delta, 0.1)
	time_acc += d
	for t in targets:
		if t["flash"] > 0.0:
			t["flash"] = maxf(0.0, t["flash"] - d)
	if hud_message.visible and Time.get_ticks_msec() > message_until_ms:
		hud_message.visible = false
	if police_anim_t < 1.0:
		police_anim_t = minf(1.0, police_anim_t + d / 0.22)
	if state == State.PLAYING:
		elapsed += d
		step_timer += d
		if step_timer >= step_time:
			step_timer = fmod(step_timer, step_time)
			_thief_step()
			if thief_steps >= track_len:
				state = State.LOST
				_show_result(false)
		cam_x = lerpf(cam_x, _cam_target(), minf(1.0, d * 4.0))
		_update_hud()
	queue_redraw()


func _draw() -> void:
	_draw_city()
	_draw_road()
	_draw_targets()
	_draw_runners()
	_draw_progress_bar()


func _draw_city() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, ROAD_TOP), Color(0.78, 0.88, 0.96))
	draw_circle(Vector2(1120, 70), 38, Color(1.0, 0.9, 0.55, 0.95))
	# 远景楼（慢速视差，循环滚动）
	for i in 9:
		var bx := fposmod(i * 200.0 - cam_x * 0.35, 1800.0) - 260.0
		var bh := 130.0 + (i % 4) * 42.0
		draw_rect(Rect2(bx, ROAD_TOP - 26 - bh, 150, bh), Color(0.66, 0.76, 0.85))
	# 近景楼（快速视差）
	for i in 7:
		var bx := fposmod(i * 260.0 + 90.0 - cam_x * 0.7, 1820.0) - 280.0
		var bh := 190.0 + (i % 3) * 56.0
		draw_rect(Rect2(bx, ROAD_TOP - 26 - bh, 170, bh), Color(0.52, 0.63, 0.74))
		for r in int(bh / 46.0):
			for c in 3:
				draw_rect(Rect2(bx + 18 + c * 52, ROAD_TOP - 26 - bh + 18 + r * 46, 26, 24),
					Color(1, 1, 1, 0.45))
	draw_rect(Rect2(0, ROAD_TOP - 26, VIEW.x, 26), Color(0.85, 0.82, 0.74))
	draw_rect(Rect2(0, ROAD_TOP - 30, VIEW.x, 4), Color(0.7, 0.66, 0.58))


func _draw_road() -> void:
	draw_rect(Rect2(0, ROAD_TOP, VIEW.x, ROAD_BOTTOM - ROAD_TOP), Color(0.3, 0.32, 0.36))
	for i in 14:
		var lx := fposmod(i * 130.0 - cam_x, 1820.0) - 120.0
		draw_rect(Rect2(lx, (ROAD_TOP + ROAD_BOTTOM) * 0.5 - 5, 60, 10), Color(0.9, 0.85, 0.5, 0.75))
	# 逃脱点（赛道尽头）
	var ex := track_len * SPACING + 120.0 - cam_x
	if ex > -140.0 and ex < VIEW.x + 140.0:
		draw_rect(Rect2(ex - 46, ROAD_TOP - 130, 92, ROAD_BOTTOM - ROAD_TOP + 130), Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(ex - 52, ROAD_TOP - 138, 104, 12), Color(0.85, 0.3, 0.25))
		draw_string(UI_FONT, Vector2(ex - 52, ROAD_TOP - 148), "逃脱点",
			HORIZONTAL_ALIGNMENT_CENTER, 104, 26, Color(0.85, 0.3, 0.25))


func _draw_targets() -> void:
	var lo := maxi(0, int(cam_x / SPACING) - 1)
	var hi := mini(targets.size(), int((cam_x + VIEW.x) / SPACING) + 2)
	for i in range(lo, hi):
		var t: Dictionary = targets[i]
		var sx := (i + 1) * SPACING - cam_x
		if sx < -120.0 or sx > VIEW.x + 120.0:
			continue
		var text: String = t["text"]
		var is_current: bool = i == next_target and state == State.PLAYING
		var font_size := 32 if level == 1 else 24
		var tw := LATIN_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var sign_size := Vector2(tw + 30, 46)
		var sign_pos := Vector2(sx - sign_size.x * 0.5, ROAD_TOP - 104.0 - sign_size.y)
		draw_line(Vector2(sx, sign_pos.y + sign_size.y), Vector2(sx, ROAD_TOP - 8.0),
			Color(0.55, 0.58, 0.62), 4.0)
		if is_current:
			var halo_r := 42.0 + sin(time_acc * 5.0) * 4.0
			draw_arc(Vector2(sx, sign_pos.y + sign_size.y * 0.5), halo_r, 0, TAU, 36,
				Color(1.0, 0.83, 0.2, 0.85), 4)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(3)
		if t["done"]:
			sb.bg_color = Color(0.88, 0.95, 0.85)
			sb.border_color = Color(0.44, 0.68, 0.29)
		elif is_current:
			sb.border_color = Color(0.85, 0.3, 0.25) if t["flash"] > 0.0 else Color(0.95, 0.69, 0.21)
			sb.bg_color = Color(0.99, 0.9, 0.88) if t["flash"] > 0.0 else Color(1.0, 0.97, 0.88)
		else:
			sb.bg_color = Color(1, 1, 1, 0.92)
			sb.border_color = Color(0.78, 0.82, 0.86)
		draw_style_box(sb, Rect2(sign_pos, sign_size))
		var base_y := sign_pos.y + sign_size.y * 0.5 + font_size * 0.36
		var text_color := Color(0.85, 0.3, 0.25) if t["flash"] > 0.0 else Color(0.26, 0.3, 0.36)
		var typed_part := text.substr(0, typed_len if is_current else 0)
		if typed_part != "":
			var w1 := LATIN_FONT.get_string_size(typed_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(LATIN_FONT, Vector2(sign_pos.x + 15, base_y), typed_part,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.18, 0.55, 0.23))
			draw_string(LATIN_FONT, Vector2(sign_pos.x + 15 + w1, base_y), text.substr(typed_len),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
		else:
			draw_string(LATIN_FONT, Vector2(sign_pos.x + 15, base_y), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _thief_vis_steps() -> float:
	if state != State.PLAYING:
		return thief_steps
	return thief_steps + step_timer / step_time


func _draw_runners() -> void:
	var foot_y := ROAD_BOTTOM - 62.0
	var thief_x := _thief_vis_steps() * SPACING - cam_x
	if state == State.WON:
		thief_x += 52.0
	var police_vis := police_steps
	if police_anim_t < 1.0:
		police_vis = lerpf(police_from, police_steps, smoothstep(0.0, 1.0, police_anim_t))
	var police_x := police_vis * SPACING - cam_x
	var running := state == State.PLAYING
	_draw_runner(Vector2(thief_x, foot_y), time_acc * 11.0, true, running, state == State.WON)
	var hop := 0.0
	if police_anim_t < 1.0:
		hop = sin(PI * police_anim_t) * 26.0
	_draw_runner(Vector2(police_x, foot_y - hop), time_acc * 13.0 + 0.6, false, running, false)
	# 小偷完全跑出屏幕时，右缘给距离指示
	if state == State.PLAYING and thief_x > VIEW.x + 40.0:
		var gap := maxi(1, ceili(thief_steps - police_steps))
		var iy := ROAD_TOP + 92.0
		var label := "小偷在前方 %d 步" % gap
		var lw := UI_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var label_cx := VIEW.x - 12.0 - lw * 0.5
		draw_circle(Vector2(label_cx, iy - 26), 15, Color(0.98, 0.83, 0.68))
		draw_arc(Vector2(label_cx, iy - 28), 15, 0, PI, 16, Color(0.2, 0.2, 0.24), 9)
		draw_string(UI_FONT, Vector2(VIEW.x - 12.0 - lw, iy + 16), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.95))


func _draw_runner(pos: Vector2, phase: Variant, is_thief: bool, running: bool, caught: bool) -> void:
	# 阴影
	_draw_ellipse(pos + Vector2(0, 4), 26, 8, Color(0, 0, 0, 0.22))
	var swing := sin(phase) * 13.0 if running else 0.0
	var swing2 := sin(phase + PI) * 13.0 if running else 0.0
	# 双腿
	_draw_ellipse(pos + Vector2(swing * 0.6, -14), 6, 16, Color(0.2, 0.22, 0.3))
	_draw_ellipse(pos + Vector2(swing2 * 0.6, -14), 6, 16, Color(0.2, 0.22, 0.3))
	# 身体
	var body_color := Color(0.9, 0.9, 0.88) if is_thief else Color(0.25, 0.42, 0.65)
	_draw_ellipse(pos + Vector2(0, -48), 20, 26, body_color)
	if is_thief:
		# 黑白条纹囚衣
		for k in 3:
			_draw_ellipse(pos + Vector2(0, -58 + k * 13), 18, 5, Color(0.25, 0.26, 0.3))
	else:
		draw_rect(Rect2(pos.x - 14, pos.y - 52, 28, 6), Color(0.18, 0.3, 0.5))
	# 手臂
	var arm := sin(phase + PI) * 10.0 if running else (16.0 if caught else 0.0)
	_draw_ellipse(pos + Vector2(-arm * 0.4, -48), 5, 14, body_color.darkened(0.1))
	# 头
	var head := pos + Vector2(4, -82)
	draw_circle(head, 15, Color(0.98, 0.83, 0.68))
	if is_thief:
		# 黑色毛线帽
		draw_arc(head + Vector2(0, -2), 15, 0, PI, 16, Color(0.2, 0.2, 0.24), 9)
		_draw_ellipse(head + Vector2(0, -6), 15, 5, Color(0.2, 0.2, 0.24))
	else:
		# 警帽
		_draw_ellipse(head + Vector2(0, -8), 16, 7, Color(0.16, 0.28, 0.46))
		draw_rect(Rect2(head.x - 18, head.y - 8, 36, 4), Color(0.12, 0.2, 0.34))
		draw_circle(head + Vector2(0, -8), 3, Color(0.95, 0.78, 0.2))
	# 眼睛（朝右边跑）
	draw_circle(head + Vector2(6, -2), 2.2, Color(0.15, 0.15, 0.15))
	draw_circle(head + Vector2(11, -2), 2.2, Color(0.15, 0.15, 0.15))


func _draw_progress_bar() -> void:
	var rect := Rect2(400, 16, 480, 12)
	draw_rect(rect, Color(0, 0, 0, 0.14))
	draw_rect(Rect2(rect.end.x - 3, rect.position.y - 4, 3, rect.size.y + 8), Color(0.85, 0.3, 0.25))
	var thief_r := clampf(thief_steps / float(track_len), 0.0, 1.0)
	var police_r := clampf(police_steps / float(track_len), 0.0, 1.0)
	draw_circle(Vector2(rect.position.x + thief_r * rect.size.x, rect.get_center().y), 8,
		Color(0.85, 0.45, 0.2))
	draw_circle(Vector2(rect.position.x + police_r * rect.size.x, rect.get_center().y), 8,
		Color(0.25, 0.42, 0.65))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, ry / maxf(rx, 0.001)))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
