extends Control
## 初始界面：四款小游戏卡片沿竖直轴“旋转木马”排布，
## 用方向键 / A D 转动，转到中间后回车或点击进入。

const UI_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const FROG_MENU_SCENE := "res://scenes/frog_river/frog_river_menu.tscn"
const COP_MENU_SCENE := "res://scenes/cops_robber/cop_chase_menu.tscn"
const SNOW_MENU_SCENE := "res://scenes/snowball/snow_fight_menu.tscn"
const BALLOON_MENU_SCENE := "res://scenes/memory_balloon/balloon_pop_menu.tscn"

const GAMES: Array = [
	{"title": "小青蛙过河", "subtitle": "字母与单词 · 两个关卡", "icon": "frog", "scene": FROG_MENU_SCENE, "available": true},
	{"title": "警察抓小偷", "subtitle": "字母与单词 · 两个关卡", "icon": "badge", "scene": COP_MENU_SCENE, "available": true},
	{"title": "打雪球", "subtitle": "字母与单词 · 两个关卡", "icon": "snow", "scene": SNOW_MENU_SCENE, "available": true},
	{"title": "记忆气球", "subtitle": "字母与单词 · 两个关卡", "icon": "balloon", "scene": BALLOON_MENU_SCENE, "available": true},
]

const STEP := TAU / 4.0
const WHEEL_CENTER := Vector2(640.0, 436.0)
const WHEEL_RADIUS := 430.0
const CARD_SIZE := Vector2(320.0, 380.0)

const COLOR_TITLE := Color(0.21, 0.31, 0.16)
const COLOR_SUB := Color(0.48, 0.54, 0.44)
const COLOR_BORDER := Color(0.72, 0.79, 0.65)
const COLOR_BORDER_FRONT := Color(0.95, 0.69, 0.21)

var selected := 0
var wheel_angle := 0.0
var target_angle := 0.0
var toast_text := ""
var toast_until_ms := 0

var toast_label: Label


func _ready() -> void:
	SaveStore.reload_from_disk()
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 24
	theme = ui_theme
	_build_labels()


func _build_labels() -> void:
	var title := Label.new()
	title.text = "打字练习乐园"
	title.position = Vector2(0, 34)
	title.size = Vector2(1280, 76)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "转一转，选一个小游戏开始吧"
	subtitle.position = Vector2(0, 112)
	subtitle.size = Vector2(1280, 34)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", COLOR_SUB)
	add_child(subtitle)

	toast_label = Label.new()
	toast_label.position = Vector2(0, 640)
	toast_label.size = Vector2(1280, 32)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 24)
	toast_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	add_child(toast_label)

	var hint := Label.new()
	hint.text = "A / D 或方向键转动 · 回车 / 点击进入"
	hint.position = Vector2(0, 684)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.5, 0.9))
	add_child(hint)


func _rotate_to(index: int) -> void:
	if index == selected:
		return
	Sfx.play("move")
	selected = index
	# 转角永远走最短弧（±90°），避免跨圈扫过中间所有卡片
	target_angle += wrapf(selected * STEP - target_angle, -PI, PI)


func _process(delta: float) -> void:
	wheel_angle = lerpf(wheel_angle, target_angle, minf(1.0, delta * 10.0))
	if absf(wheel_angle - target_angle) < 0.0004:
		wheel_angle = target_angle
	if toast_text != "" and Time.get_ticks_msec() > toast_until_ms:
		toast_text = ""
		toast_label.text = ""
	queue_redraw()


func _card_state(index: int) -> Dictionary:
	var rel := wrapf(index * STEP - wheel_angle, -PI, PI)
	var depth := cos(rel)
	var s := 0.55 + 0.45 * (depth + 1.0) * 0.5
	var size := CARD_SIZE * s
	var pos := Vector2(
		WHEEL_CENTER.x + sin(rel) * WHEEL_RADIUS,
		WHEEL_CENTER.y - (1.0 - s) * 34.0
	) - size * 0.5
	return {"rect": Rect2(pos, size), "depth": depth, "scale": s}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in GAMES.size():
			var st := _card_state(i)
			if (st["rect"] as Rect2).has_point(event.position):
				if i == selected:
					_activate()
				else:
					_rotate_to(i)
				return


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT, KEY_D:
				_rotate_to((selected + 1) % GAMES.size())
			KEY_LEFT, KEY_A:
				_rotate_to((selected + GAMES.size() - 1) % GAMES.size())
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate()


func _activate() -> void:
	var game: Dictionary = GAMES[selected]
	if game["available"]:
		Sfx.play("confirm")
		get_tree().change_scene_to_file(game["scene"])
	else:
		Sfx.play("wrong")
		_show_toast("这个小游戏还没有做好，敬请期待！")


func _show_toast(text: String) -> void:
	toast_text = text
	toast_label.text = text
	toast_until_ms = Time.get_ticks_msec() + 1800


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.93, 0.96, 0.88))
	draw_circle(Vector2(1140, 84), 44, Color(1.0, 0.9, 0.55, 0.9))
	_draw_cloud(Vector2(190, 100), 1.0)
	_draw_cloud(Vector2(440, 66), 0.7)
	draw_rect(Rect2(0, 656, 1280, 64), Color(0.66, 0.84, 0.47))
	for i in 6:
		var fx := 90.0 + i * 214.0
		var fy := 676.0 + (i % 2) * 10.0
		draw_circle(Vector2(fx, fy), 7, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(fx, fy), 3, Color(1, 0.85, 0.3, 0.9))

	var order := range(GAMES.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return _card_state(a)["depth"] < _card_state(b)["depth"])
	for i in order:
		_draw_card(i)


func _draw_card(index: int) -> void:
	var game: Dictionary = GAMES[index]
	var st := _card_state(index)
	var rect: Rect2 = st["rect"]
	var s: float = st["scale"]
	var front := index == selected
	var alpha := 0.35 + 0.65 * ((st["depth"] as float) + 1.0) * 0.5

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, alpha)
	sb.set_corner_radius_all(int(26 * s))
	sb.set_border_width_all(int(5 * s))
	sb.border_color = COLOR_BORDER_FRONT if front else COLOR_BORDER
	sb.shadow_color = Color(0.2, 0.35, 0.15, 0.16 * alpha)
	sb.shadow_size = int(10 * s)
	sb.shadow_offset = Vector2(0, 4 * s)
	draw_style_box(sb, rect)

	var icon_center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.34)
	draw_circle(icon_center, 92 * s, Color(0.93, 0.96, 0.88, alpha))
	match str(game["icon"]):
		"frog":
			_draw_frog_icon(icon_center, s, alpha)
		"badge":
			_draw_badge_icon(icon_center, s, alpha)
		"snow":
			_draw_snowflake_icon(icon_center, s, alpha)
		"balloon":
			_draw_balloon_icon(icon_center, s, alpha)
		_:
			_draw_lock_icon(icon_center, s, alpha)

	var title: String = game["title"]
	var title_size := int(38 * s)
	var tw := UI_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	draw_string(UI_FONT, Vector2(rect.get_center().x - tw * 0.5, rect.position.y + rect.size.y * 0.68),
		title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(COLOR_TITLE, alpha))

	var sub: String = game["subtitle"]
	var sub_size := int(22 * s)
	var sw := UI_FONT.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
	draw_string(UI_FONT, Vector2(rect.get_center().x - sw * 0.5, rect.position.y + rect.size.y * 0.79),
		sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color(COLOR_SUB, alpha))

	if front and game["available"]:
		var tag := "点击进入"
		var tag_size := int(24 * s)
		var tagw := UI_FONT.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x
		draw_string(UI_FONT, Vector2(rect.get_center().x - tagw * 0.5, rect.position.y + rect.size.y * 0.92),
			tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size, Color(0.85, 0.5, 0.1, alpha))


func _draw_frog_icon(center: Vector2, s: float, alpha: float) -> void:
	var body := Color(0.35, 0.69, 0.3, alpha)
	var dark := Color(0.19, 0.42, 0.16, alpha)
	_draw_ellipse(center + Vector2(0, 10 * s), 56 * s, 42 * s, body)
	_draw_ellipse(center + Vector2(0, 24 * s), 28 * s, 16 * s, Color(0.63, 0.85, 0.52, alpha))
	for off in [-24.0, 24.0]:
		draw_circle(center + Vector2(off * s, -34 * s), 15 * s, body)
		draw_circle(center + Vector2(off * s, -36 * s), 9 * s, Color(1, 1, 1, alpha))
		draw_circle(center + Vector2(off * s, -37 * s), 4 * s, Color(0.15, 0.2, 0.12, alpha))
	draw_arc(center + Vector2(0, 4 * s), 16 * s, 0.35, PI - 0.35, 12, dark, maxf(2.0, 3.0 * s))
	draw_circle(center + Vector2(-34 * s, 0), 7 * s, Color(1, 0.6, 0.6, 0.55 * alpha))
	draw_circle(center + Vector2(34 * s, 0), 7 * s, Color(1, 0.6, 0.6, 0.55 * alpha))


func _draw_badge_icon(center: Vector2, s: float, alpha: float) -> void:
	var gold := Color(0.95, 0.78, 0.2, alpha)
	var navy := Color(0.22, 0.32, 0.5, alpha)
	var top := center.y - 46.0 * s
	var mid := center.y + 8.0 * s
	var bottom := center.y + 50.0 * s
	var half_w := 54.0 * s
	var pts := PackedVector2Array([
		Vector2(center.x - half_w, top),
		Vector2(center.x + half_w, top),
		Vector2(center.x + half_w, mid),
		Vector2(center.x, bottom),
		Vector2(center.x - half_w, mid),
	])
	draw_colored_polygon(pts, gold)
	var star_pts := PackedVector2Array()
	for k in 10:
		var angle := -PI / 2.0 + k * PI / 5.0
		var r := (22.0 if k % 2 == 0 else 9.5) * s
		star_pts.push_back(center + Vector2(0, -8 * s) + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(star_pts, navy)


func _draw_snowflake_icon(center: Vector2, s: float, alpha: float) -> void:
	var col := Color(0.5, 0.7, 0.9, alpha)
	for k in 6:
		var dir := Vector2(cos(k * PI / 3.0), sin(k * PI / 3.0))
		var tip := center + dir * 56.0 * s
		draw_line(center, tip, col, 5.0 * s)
		var base := center + dir * 34.0 * s
		draw_line(base, base + dir.rotated(PI / 5.0) * 16.0 * s, col, 3.5 * s)
		draw_line(base, base + dir.rotated(-PI / 5.0) * 16.0 * s, col, 3.5 * s)
	draw_circle(center, 7.0 * s, col)


func _draw_balloon_icon(center: Vector2, s: float, alpha: float) -> void:
	var col := Color(0.9, 0.48, 0.58, alpha)
	_draw_ellipse(center + Vector2(0, -6 * s), 36 * s, 44 * s, col)
	_draw_ellipse(center + Vector2(-11 * s, -22 * s), 10 * s, 14 * s, Color(1, 1, 1, 0.75 * alpha))
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-7 * s, 38 * s),
			center + Vector2(7 * s, 38 * s),
			center + Vector2(0, 30 * s),
		]),
		PackedColorArray([col, col, col])
	)
	draw_line(center + Vector2(0, 38 * s), center + Vector2(6 * s, 74 * s),
		Color(0.4, 0.4, 0.45, alpha), 2.5 * s)


func _draw_lock_icon(center: Vector2, s: float, alpha: float) -> void:
	var col := Color(0.62, 0.66, 0.58, alpha)
	draw_arc(center + Vector2(0, -14 * s), 18 * s, PI, TAU, 16, col, maxf(3.0, 6.0 * s))
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(8 * s))
	draw_style_box(sb, Rect2(center - Vector2(26 * s, 14 * s), Vector2(52 * s, 40 * s)))
	draw_circle(center + Vector2(0, -2 * s), 5 * s, Color(0.35, 0.38, 0.33, alpha))


func _draw_cloud(center: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	for data in [[0.0, 0.0, 34.0], [-30.0, 8.0, 24.0], [30.0, 8.0, 24.0]]:
		draw_circle(center + Vector2(data[0] * s, data[1] * s), data[2] * s, col)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, ry / maxf(rx, 0.001)))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
