extends Control
## 记忆气球主玩法。
## 气球从底部匀速升起，上面的字母/单词显示几秒后淡出（气球继续上升）；
## 直接敲键盘：输入序列自动匹配以其开头的气球（匹配进度只显示在顶部提示，
## 不标在气球上——凭记忆打），打完整字母/单词气球爆炸成烟花。
## 多个相同目标炸最高（最接近顶部、最危险的）；任一气球飘出顶部即失败；
## 炸够目标数量获胜。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const LATIN_FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const BALLOON_MENU_SCENE := "res://scenes/memory_balloon/balloon_pop_menu.tscn"
const START_MENU_SCENE := "res://scenes/start_menu.tscn"

const VIEW := Vector2(1280.0, 720.0)
const TOP_Y := 110.0
const SPAWN_Y := 660.0
const MAX_ON_SCREEN := 5
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const BALLOON_COLORS: Array = [
	Color(0.92, 0.5, 0.6),
	Color(0.98, 0.82, 0.42),
	Color(0.55, 0.75, 0.95),
	Color(0.62, 0.85, 0.58),
	Color(0.75, 0.62, 0.92),
]

# 关卡参数：目标炸球数 / 上升全程用时 / 文字显示时长 / 生成间隔起点→终点（秒）/ 气球半径
const LEVEL_PARAMS := {
	1: {"goal": 20, "rise_time": 13.0, "display": 2.5, "interval_from": 3.2, "interval_to": 2.2, "radius": 44.0},
	2: {"goal": 12, "rise_time": 15.0, "display": 4.0, "interval_from": 5.0, "interval_to": 4.0, "radius": 54.0},
}

const FW_LIFE := 1.1  # 烟花粒子寿命（秒）

enum State { PLAYING, WON, LOST }

var level := 1
var goal := 20
var rise_time := 13.0
var display_time := 2.5
var interval_from := 3.2
var interval_to := 2.2
var radius := 44.0

var balls: Array = []       # {text, zh, base_x, y, speed, phase, age, color_idx, dead}
var word_pool: Array = []
var typed := ""
var smashed := 0
var mistakes := 0
var elapsed := 0.0
var spawn_timer := 0.0
var spawned_count := 0
var particles: Array = []
var stars: Array = []
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
	level = GameSession.balloon_level
	var params: Dictionary = LEVEL_PARAMS[level]
	goal = params["goal"]
	rise_time = params["rise_time"]
	display_time = params["display"]
	interval_from = params["interval_from"]
	interval_to = params["interval_to"]
	radius = params["radius"]
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	for i in 60:
		stars.append({
			"x": fposmod(i * 197.3, VIEW.x),
			"y": fposmod(i * 131.7, 480.0) + 16.0,
			"r": 1.4 + (i % 3) * 0.7,
			"phase": float(i) * 0.9,
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
	spawned_count = 0
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
	var x := randf_range(120.0, VIEW.x - 120.0)
	for attempt in 8:
		var ok := true
		for b in balls:
			if not b["dead"] and absf(b["base_x"] - x) < radius * 2.4:
				ok = false
				break
		if ok:
			break
		x = randf_range(120.0, VIEW.x - 120.0)
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
		"speed": (SPAWN_Y - TOP_Y) / rise_time,
		"phase": randf() * TAU, "age": 0.0,
		"color_idx": spawned_count % BALLOON_COLORS.size(),
		"dead": false,
	})
	spawned_count += 1


func _ball_x(b: Dictionary) -> float:
	return b["base_x"] + sin(time_acc * 1.4 + b["phase"]) * 10.0


func _build_hud() -> void:
	hud_level = Label.new()
	hud_level.position = Vector2(24, 10)
	hud_level.size = Vector2(520, 38)
	hud_level.add_theme_font_size_override("font_size", 30)
	hud_level.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	add_child(hud_level)

	hud_progress = Label.new()
	hud_progress.position = Vector2(700, 16)
	hud_progress.size = Vector2(556, 32)
	hud_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_progress.add_theme_font_size_override("font_size", 26)
	hud_progress.add_theme_color_override("font_color", Color(0.7, 0.76, 0.88))
	add_child(hud_progress)

	hud_prompt = RichTextLabel.new()
	hud_prompt.position = Vector2(0, 58)
	hud_prompt.size = Vector2(1280, 56)
	hud_prompt.bbcode_enabled = true
	hud_prompt.scroll_active = false
	hud_prompt.add_theme_font_size_override("normal_font_size", 38)
	hud_prompt.add_theme_color_override("default_color", Color(0.85, 0.9, 1.0))
	add_child(hud_prompt)

	hud_message = Label.new()
	hud_message.position = Vector2(0, 120)
	hud_message.size = Vector2(1280, 36)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.add_theme_font_size_override("font_size", 30)
	hud_message.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	hud_message.visible = false
	add_child(hud_message)

	var hint := Label.new()
	hint.text = "按键盘 A 到 Z 输入 · 炸整球才算 · 任一气球飞出顶部即失败 · Esc 返回选关"
	hint.position = Vector2(0, 688)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8, 0.95))
	add_child(hint)


func _build_result_layer() -> void:
	result_layer = Control.new()
	result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.06, 0.12, 0.55)
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
	result_title.text = "满天烟花！"
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

	var buttons := MenuButtonRow.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	buttons.setup([
		{"text": "再来一次", "action": func() -> void: _start_level()},
		{"text": "选关卡", "action": func() -> void: get_tree().change_scene_to_file(BALLOON_MENU_SCENE)},
		{"text": "主菜单", "action": func() -> void: get_tree().change_scene_to_file(START_MENU_SCENE)},
	])
	vbox.add_child(buttons)

	result_layer.visible = false
	add_child(result_layer)


func _update_hud() -> void:
	var level_name := "字母" if level == 1 else "单词"
	hud_level.text = "记忆气球 · 第 %d 关（%s）" % [level, level_name]
	hud_progress.text = "已炸 %d / %d · 失误 %d" % [smashed, goal, mistakes]
	if state == State.WON:
		hud_prompt.text = "[center][color=#7fe08a]满天烟花！[/color][/center]"
		return
	if state == State.LOST:
		hud_prompt.text = "[center][color=#ffb3a7]气球飞走了！[/color][/center]"
		return
	if typed == "":
		hud_prompt.text = "[center]记住气球上的字，飞走前打出来！[/center]"
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
		get_tree().change_scene_to_file(BALLOON_MENU_SCENE)
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
	var best_y := 1e9
	for b in balls:
		if b["dead"]:
			continue
		var t: String = b["text"]
		if prefix.length() <= t.length() and t.substr(0, prefix.length()).to_lower() == prefix:
			if b["y"] < best_y:
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
		_firework(Vector2(_ball_x(best), best["y"]))
		hud_message.visible = false
		if smashed >= goal:
			state = State.WON
			_show_result(true)
	_update_hud()


func _firework(pos: Vector2) -> void:
	var base: Color = BALLOON_COLORS[randi() % BALLOON_COLORS.size()]
	for i in 18:
		var ang := TAU * float(i) / 18.0 + randf_range(-0.1, 0.1)
		var col := base.lightened(randf_range(0.0, 0.35))
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(160.0, 360.0),
			"t": 0.0,
			"r": randf_range(4.0, 8.5),
			"col": col,
		})
	particles.append({"pos": pos, "vel": Vector2.ZERO, "t": 0.0, "r": 16.0, "col": Color(1, 1, 1, 0.9), "ring": true})


func _show_result(win: bool) -> void:
	result_layer.visible = true
	if win:
		result_title.text = "满天烟花！"
		result_title.add_theme_color_override("font_color", Color(0.2, 0.55, 0.25))
		result_stars.count = 3 if mistakes == 0 else (2 if mistakes <= 2 else 1)
		result_stats.text = "用时 %d 秒 · 失误 %d 次" % [int(elapsed), mistakes]
	else:
		result_title.text = "气球飞走了…"
		result_title.add_theme_color_override("font_color", Color(0.75, 0.25, 0.2))
		result_stars.count = 0
		result_stats.text = "炸掉 %d / %d 个 · 失误 %d 次" % [smashed, goal, mistakes]
	hud_message.visible = false
	_update_hud()


func _process(delta: float) -> void:
	var d := minf(delta, 0.1)
	time_acc += d
	if hud_message.visible and Time.get_ticks_msec() > message_until_ms:
		hud_message.visible = false
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["t"] += d
		if not p.has("ring"):
			p["vel"] = p["vel"] + Vector2(0, 150) * d
			p["pos"] = p["pos"] + p["vel"] * d
		if p["t"] > FW_LIFE:
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
			b["age"] += d
			b["y"] -= b["speed"] * d
			if b["y"] <= TOP_Y:
				b["dead"] = true
				_firework(Vector2(_ball_x(b), b["y"]))
				state = State.LOST
				_show_result(false)
				break
	queue_redraw()


func _draw() -> void:
	_draw_night()
	_draw_balloons()
	_draw_particles()


func _draw_night() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, VIEW.y), Color(0.12, 0.16, 0.28))
	for s in stars:
		var tw := 0.45 + 0.35 * sin(time_acc * 1.8 + s["phase"])
		draw_circle(Vector2(s["x"], s["y"]), s["r"], Color(1, 1, 1, tw))
	draw_circle(Vector2(1105, 92), 40, Color(0.93, 0.93, 0.82, 0.95))
	draw_circle(Vector2(1090, 84), 36, Color(0.12, 0.16, 0.28))
	var hills := PackedVector2Array([
		Vector2(0, VIEW.y), Vector2(0, 640), Vector2(230, 560),
		Vector2(510, 650), Vector2(760, 566), Vector2(1040, 655), Vector2(VIEW.x, 596),
		Vector2(VIEW.x, VIEW.y),
	])
	draw_colored_polygon(hills, Color(0.07, 0.09, 0.16))
	draw_rect(Rect2(0, 672, VIEW.x, VIEW.y - 672), Color(0.07, 0.09, 0.16))


func _draw_balloons() -> void:
	var font_size := 36 if level == 1 else 26
	for b in balls:
		if b["dead"]:
			continue
		var by: float = b["y"]
		if by - radius * 1.3 > VIEW.y or by + radius * 1.3 < -40.0:
			continue
		var bx := _ball_x(b)
		var col: Color = BALLOON_COLORS[b["color_idx"]]
		var danger := by < TOP_Y + 240.0
		var spawn_alpha := clampf(float(b["age"]) / 0.35, 0.0, 1.0)
		# 气球线
		var line_top := Vector2(bx, by + radius * 1.22)
		var line_bot := line_top + Vector2(sin(time_acc * 1.6 + b["phase"]) * 7.0, 84.0)
		draw_line(line_top, line_bot, Color(0.6, 0.63, 0.72, 0.65 * spawn_alpha), 2.0)
		# 危险提示光环
		if danger and state == State.PLAYING:
			var halo := radius + 9.0 + sin(time_acc * 6.0) * 3.0
			draw_arc(Vector2(bx, by), halo, 0, TAU, 36, Color(1.0, 0.45, 0.4, 0.8 * spawn_alpha), 4)
		# 球体（椭圆）
		draw_set_transform(Vector2(bx, by), 0.0, Vector2(1.0, 1.15))
		draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, spawn_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 高光
		draw_circle(Vector2(bx - radius * 0.32, by - radius * 0.42), radius * 0.26,
			Color(1, 1, 1, 0.65 * spawn_alpha))
		# 底部结
		var knot := PackedVector2Array([
			Vector2(bx - 7, by + radius * 1.12),
			Vector2(bx + 7, by + radius * 1.12),
			Vector2(bx, by + radius * 0.96),
		])
		draw_polygon(knot, PackedColorArray([
			Color(col.darkened(0.1), spawn_alpha),
			Color(col.darkened(0.1), spawn_alpha),
			Color(col.darkened(0.1), spawn_alpha),
		]))
		# 文字（显示期 + 淡出）
		var alpha := clampf((display_time + 0.45 - float(b["age"])) / 0.45, 0.0, 1.0)
		alpha *= spawn_alpha
		if alpha <= 0.0:
			continue
		var text: String = b["text"]
		var tw := LATIN_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos := Vector2(bx - tw * 0.5, by + font_size * 0.36)
		draw_string(LATIN_FONT, pos + Vector2(1.5, 1.5), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.15, 0.18, 0.28, alpha))
		draw_string(LATIN_FONT, pos, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, alpha))


func _draw_particles() -> void:
	for p in particles:
		var k: float = p["t"] / FW_LIFE
		var col: Color = p["col"]
		col.a *= (1.0 - k)
		if p.has("ring"):
			draw_arc(p["pos"], 18 + k * 150, 0, TAU, 32, col, 3.5)
		else:
			draw_circle(p["pos"], p["r"] * (1.0 - k * 0.5), col)
