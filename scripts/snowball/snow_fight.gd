extends Control
## 打雪球主玩法。
## 雪球从顶部按节奏先后出现并匀速下落（同屏不超过 5 个，越打越快）；
## 直接敲键盘：输入序列自动匹配以其开头的雪球，匹配部分绿色高亮，
## 打完整字母/单词即击碎（多个相同目标击碎最低最危险的）。
## 击碎目标数量获胜；任一雪球落到雪地即失败。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const LATIN_FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const SNOW_MENU_SCENE := "res://scenes/snowball/snow_fight_menu.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"

const VIEW := Vector2(1280.0, 720.0)
const GROUND_Y := 640.0
const SPAWN_Y := -60.0
const MAX_ON_SCREEN := 5
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# 关卡参数：目标击碎数 / 下落全程用时 / 生成间隔起点→终点（秒）/ 雪球半径
const LEVEL_PARAMS := {
	1: {"goal": 20, "fall_time": 8.2, "interval_from": 3.0, "interval_to": 2.0, "radius": 40.0},
	2: {"goal": 12, "fall_time": 10.0, "interval_from": 5.0, "interval_to": 4.0, "radius": 52.0},
}

enum State { PLAYING, WON, LOST }

var level := 1
var goal := 20
var fall_time := 8.2
var interval_from := 3.0
var interval_to := 2.0
var radius := 40.0

var balls: Array = []       # {text, zh, base_x, y, speed, phase, dead}
var word_pool: Array = []
var typed := ""             # 当前输入缓冲（小写）
var smashed := 0
var mistakes := 0
var elapsed := 0.0
var spawn_timer := 0.0
var particles: Array = []   # {pos, vel, t, r}
var snowflakes: Array = []  # 背景装饰雪花
var prev_letter := ""
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
var result_stars: StarRow


func _ready() -> void:
	level = GameSession.snow_level
	var params: Dictionary = LEVEL_PARAMS[level]
	goal = params["goal"]
	fall_time = params["fall_time"]
	interval_from = params["interval_from"]
	interval_to = params["interval_to"]
	radius = params["radius"]
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	for i in 34:
		snowflakes.append({
			"x": randf_range(0.0, VIEW.x),
			"y": randf_range(0.0, VIEW.y),
			"sp": randf_range(40.0, 95.0),
			"r": randf_range(1.8, 3.8),
			"phase": randf() * TAU,
		})
	_build_hud()
	_build_result_layer()
	_start_level()


func _start_level() -> void:
	balls.clear()
	word_pool.clear()
	particles.clear()
	typed = ""
	smashed = 0
	mistakes = 0
	elapsed = 0.0
	spawn_timer = 0.0
	prev_letter = ""
	state = State.PLAYING
	if level == 2:
		word_pool = WordBank.pick_words_no_prefix_conflict(goal)
	_spawn_ball()
	hud_message.visible = false
	result_layer.visible = false
	_update_hud()


func _spawn_interval() -> float:
	var k := clampf(float(smashed) / float(goal), 0.0, 1.0)
	return lerpf(interval_from, interval_to, k)


func _active_count() -> int:
	var n := 0
	for b in balls:
		if not b["dead"]:
			n += 1
	return n


func _rand_letter() -> String:
	var ch := LETTERS[randi() % 26]
	while ch == prev_letter:
		ch = LETTERS[randi() % 26]
	prev_letter = ch
	return ch


func _spawn_ball() -> void:
	var x := randf_range(110.0, VIEW.x - 110.0)
	for attempt in 8:
		var ok := true
		for b in balls:
			if not b["dead"] and absf(b["base_x"] - x) < radius * 2.4:
				ok = false
				break
		if ok:
			break
		x = randf_range(110.0, VIEW.x - 110.0)
	var text := ""
	var zh := ""
	if level == 1:
		text = _rand_letter()
	else:
		if word_pool.is_empty():
			word_pool = WordBank.pick_words_no_prefix_conflict(goal)
		var entry: Array = word_pool.pop_front()
		text = entry[0]
		zh = entry[1]
	balls.append({
		"text": text, "zh": zh, "base_x": x, "y": SPAWN_Y,
		"speed": (GROUND_Y - SPAWN_Y) / fall_time,
		"phase": randf() * TAU, "dead": false,
	})


func _ball_x(b: Dictionary) -> float:
	return b["base_x"] + sin(time_acc * 1.6 + b["phase"]) * 8.0


func _build_hud() -> void:
	hud_level = Label.new()
	hud_level.position = Vector2(24, 10)
	hud_level.size = Vector2(520, 38)
	hud_level.add_theme_font_size_override("font_size", 30)
	hud_level.add_theme_color_override("font_color", Color(0.2, 0.3, 0.42))
	add_child(hud_level)

	hud_progress = Label.new()
	hud_progress.position = Vector2(700, 16)
	hud_progress.size = Vector2(556, 32)
	hud_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_progress.add_theme_font_size_override("font_size", 26)
	hud_progress.add_theme_color_override("font_color", Color(0.32, 0.4, 0.5))
	add_child(hud_progress)

	hud_prompt = RichTextLabel.new()
	hud_prompt.position = Vector2(0, 58)
	hud_prompt.size = Vector2(1280, 56)
	hud_prompt.bbcode_enabled = true
	hud_prompt.scroll_active = false
	hud_prompt.add_theme_font_size_override("normal_font_size", 38)
	hud_prompt.add_theme_color_override("default_color", Color(0.26, 0.32, 0.4))
	add_child(hud_prompt)

	hud_message = Label.new()
	hud_message.position = Vector2(0, 120)
	hud_message.size = Vector2(1280, 36)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.add_theme_font_size_override("font_size", 30)
	hud_message.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	hud_message.visible = false
	add_child(hud_message)

	var hint := Label.new()
	hint.text = "按键盘 A 到 Z 输入 · 击碎整球才算 · 任一雪球落地即失败 · Esc 返回选关"
	hint.position = Vector2(0, 688)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.35, 0.42, 0.5, 0.95))
	add_child(hint)


func _build_result_layer() -> void:
	result_layer = Control.new()
	result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.15, 0.22, 0.5)
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
	result_title.text = "守住啦！"
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

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	vbox.add_child(buttons)
	_result_button(buttons, "再来一次", func() -> void: _start_level())
	_result_button(buttons, "选关卡", func() -> void: get_tree().change_scene_to_file(SNOW_MENU_SCENE))
	_result_button(buttons, "主菜单", func() -> void: get_tree().change_scene_to_file(START_MENU_SCENE))

	result_layer.visible = false
	add_child(result_layer)


func _result_button(parent: Container, text: String, action: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 60)
	btn.add_theme_font_size_override("font_size", 30)
	btn.pressed.connect(action)
	parent.add_child(btn)


func _update_hud() -> void:
	var level_name := "字母" if level == 1 else "单词"
	hud_level.text = "打雪球 · 第 %d 关（%s）" % [level, level_name]
	hud_progress.text = "已击碎 %d / %d · 失误 %d" % [smashed, goal, mistakes]
	if state == State.WON:
		hud_prompt.text = "[center][color=#2e8b3a]雪球全碎了！[/color][/center]"
		return
	if state == State.LOST:
		hud_prompt.text = "[center][color=#c0392b]雪球砸到雪地了！[/color][/center]"
		return
	if typed == "":
		hud_prompt.text = "[center]看准雪球，直接开打！[/center]"
	else:
		hud_prompt.text = "[center]已输入：%s[/center]" % typed


func _show_message(text: String) -> void:
	hud_message.text = text
	hud_message.visible = true
	message_until_ms = Time.get_ticks_msec() + 1800


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(SNOW_MENU_SCENE)
		return
	if state != State.PLAYING:
		return
	var k: int = event.keycode
	if k < KEY_A or k > KEY_Z:
		return
	_handle_char(char(65 + (k - KEY_A)))


func _handle_char(c: String) -> void:
	var prefix := typed + c.to_lower()
	var best: Dictionary = {}
	var best_y := -1e9
	for b in balls:
		if b["dead"]:
			continue
		var t: String = b["text"]
		if prefix.length() <= t.length() and t.substr(0, prefix.length()).to_lower() == prefix:
			if b["y"] > best_y:
				best_y = b["y"]
				best = b
	if best.is_empty():
		mistakes += 1
		typed = ""
		_show_message("打错啦！重新输入")
		_update_hud()
		return
	typed = prefix
	if typed.length() == (best["text"] as String).length():
		best["dead"] = true
		smashed += 1
		typed = ""
		_burst(Vector2(_ball_x(best), best["y"]), 1.0)
		hud_message.visible = false
		if smashed >= goal:
			state = State.WON
			_show_result(true)
	_update_hud()


func _burst(pos: Vector2, scale: float) -> void:
	for i in 9:
		var ang := randf() * TAU
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang) - 0.6) * randf_range(90.0, 240.0) * scale,
			"t": 0.0,
			"r": randf_range(4.0, 10.0) * scale,
		})


func _show_result(win: bool) -> void:
	result_layer.visible = true
	if win:
		result_title.text = "守住啦！雪球全碎了！"
		result_title.add_theme_color_override("font_color", Color(0.2, 0.55, 0.25))
		result_stars.count = 3 if mistakes == 0 else (2 if mistakes <= 2 else 1)
		result_stats.text = "用时 %d 秒 · 失误 %d 次" % [int(elapsed), mistakes]
	else:
		result_title.text = "雪球砸到雪地了…"
		result_title.add_theme_color_override("font_color", Color(0.75, 0.25, 0.2))
		result_stars.count = 0
		result_stats.text = "击碎 %d / %d 个 · 失误 %d 次" % [smashed, goal, mistakes]
	hud_message.visible = false
	_update_hud()


func _process(delta: float) -> void:
	var d := minf(delta, 0.1)
	time_acc += d
	for f in snowflakes:
		f["y"] += f["sp"] * d
		f["x"] += sin(time_acc * 1.2 + f["phase"]) * 12.0 * d
		if f["y"] > VIEW.y + 8.0:
			f["y"] = -8.0
			f["x"] = randf_range(0.0, VIEW.x)
	if hud_message.visible and Time.get_ticks_msec() > message_until_ms:
		hud_message.visible = false
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["t"] += d
		p["vel"] = p["vel"] + Vector2(0, 620) * d
		p["pos"] = p["pos"] + p["vel"] * d
		if p["t"] > 0.65:
			particles.remove_at(i)
	if state == State.PLAYING:
		elapsed += d
		spawn_timer += d
		if spawn_timer >= _spawn_interval():
			spawn_timer = 0.0
			if _active_count() < MAX_ON_SCREEN:
				_spawn_ball()
		for b in balls:
			if b["dead"]:
				continue
			b["y"] += b["speed"] * d
			if b["y"] >= GROUND_Y - radius * 0.35:
				b["dead"] = true
				_burst(Vector2(_ball_x(b), GROUND_Y - 10.0), 1.3)
				state = State.LOST
				_show_result(false)
				break
	queue_redraw()


func _draw() -> void:
	_draw_scenery()
	_draw_balls()
	_draw_particles()


func _draw_scenery() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, VIEW.y), Color(0.84, 0.89, 0.94))
	draw_circle(Vector2(1110, 96), 40, Color(1.0, 0.96, 0.85, 0.85))
	_draw_mountain(250.0, GROUND_Y + 10.0, 300.0)
	_draw_mountain(880.0, GROUND_Y + 10.0, 400.0)
	_draw_tree(Vector2(80, GROUND_Y + 16.0))
	_draw_tree(Vector2(1200, GROUND_Y + 16.0))
	# 雪地
	draw_rect(Rect2(0, GROUND_Y + 6.0, VIEW.x, VIEW.y - GROUND_Y - 6.0), Color(0.96, 0.97, 1.0))
	for i in 10:
		draw_circle(Vector2(i * 140.0 + 40.0, GROUND_Y + 18.0), 28.0, Color(0.96, 0.97, 1.0))
	draw_rect(Rect2(0, GROUND_Y + 4.0, VIEW.x, 3.0), Color(0.78, 0.85, 0.93, 0.8))
	# 背景雪花
	for f in snowflakes:
		draw_circle(Vector2(f["x"], f["y"]), f["r"], Color(1, 1, 1, 0.85))


func _draw_mountain(center_x: float, base_y: float, half_w: float) -> void:
	var pts := PackedVector2Array([
		Vector2(center_x - half_w, base_y),
		Vector2(center_x, base_y - half_w * 0.92),
		Vector2(center_x + half_w, base_y),
	])
	draw_colored_polygon(pts, Color(0.94, 0.96, 0.99))
	draw_line(Vector2(center_x, base_y - half_w * 0.92), Vector2(center_x + half_w, base_y),
		Color(0.8, 0.86, 0.93), 3.0)


func _draw_tree(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 8, pos.y - 26, 16, 26), Color(0.4, 0.28, 0.18))
	for k in 3:
		var w := 62.0 - k * 15.0
		var top := pos.y - 30.0 - k * 38.0
		var pts := PackedVector2Array([
			Vector2(pos.x - w, top),
			Vector2(pos.x + w, top),
			Vector2(pos.x, top - 54.0),
		])
		draw_colored_polygon(pts, Color(0.22, 0.45, 0.32))
		draw_rect(Rect2(pos.x - w * 0.4, top - 6.0, w * 0.8, 7.0), Color(0.96, 0.97, 1.0))


func _draw_balls() -> void:
	var font_size := 34 if level == 1 else 25
	for b in balls:
		if b["dead"]:
			continue
		var by: float = b["y"]
		if by < -radius:
			continue
		var bx := _ball_x(b)
		var danger := by > GROUND_Y - 260.0
		var matched: bool = typed != "" and _match_len(b) > 0
		if matched:
			draw_arc(Vector2(bx, by), radius + 9.0, 0, TAU, 36, Color(0.55, 0.75, 0.95, 0.8), 4)
		draw_circle(Vector2(bx, by), radius, Color(0.97, 0.985, 1.0))
		draw_circle(Vector2(bx - radius * 0.28, by - radius * 0.3), radius * 0.55,
			Color(1, 1, 1, 0.9))
		draw_arc(Vector2(bx, by), radius, 0, TAU, 40,
			Color(0.85, 0.35, 0.3) if danger else Color(0.72, 0.8, 0.9), 3.0)
		var text: String = b["text"]
		var tw := LATIN_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var base_x := bx - tw * 0.5
		var base_y := by + font_size * 0.36
		var hl := _match_len(b)
		if hl > 0:
			var done_part := text.substr(0, hl)
			var w1 := LATIN_FONT.get_string_size(done_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(LATIN_FONT, Vector2(base_x, base_y), done_part,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.18, 0.55, 0.23))
			draw_string(LATIN_FONT, Vector2(base_x + w1, base_y), text.substr(hl),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.26, 0.32, 0.42))
		else:
			draw_string(LATIN_FONT, Vector2(base_x, base_y), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.26, 0.32, 0.42))


func _match_len(b: Dictionary) -> int:
	if typed == "":
		return 0
	var t: String = b["text"]
	if typed.length() > t.length():
		return 0
	if t.substr(0, typed.length()).to_lower() != typed:
		return 0
	return typed.length()


func _draw_particles() -> void:
	for p in particles:
		var k: float = p["t"] / 0.65
		draw_circle(p["pos"], p["r"] * (1.0 - k * 0.4), Color(1, 1, 1, 0.95 * (1.0 - k)))
