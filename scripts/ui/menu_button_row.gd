class_name MenuButtonRow
extends HBoxContainer
## 键盘 + 鼠标两用按钮行：A/D、方向键切换选中（金色边框高亮），
## 回车 / 空格确认；鼠标点击同样有效。
## 选中样式同时覆盖 normal/hover/pressed，不受鼠标悬停影响。

signal chosen(index: int)

var sel := 0
var _actions: Array = []
var _buttons: Array = []

var _style_sel := StyleBoxFlat.new()
var _style_sel_pressed := StyleBoxFlat.new()
var _font_sel := Color(0.25, 0.3, 0.2)


func _init() -> void:
	_style_sel.bg_color = Color(1.0, 0.97, 0.88)
	_style_sel.border_color = Color(0.95, 0.69, 0.21)
	_style_sel.set_border_width_all(4)
	_style_sel.set_corner_radius_all(8)
	_style_sel_pressed.bg_color = Color(0.98, 0.93, 0.8)
	_style_sel_pressed.border_color = Color(0.85, 0.6, 0.15)
	_style_sel_pressed.set_border_width_all(4)
	_style_sel_pressed.set_corner_radius_all(8)


## defs 每项：{text, action, min_size, font_size}
func setup(defs: Array) -> void:
	for d in defs:
		var btn := Button.new()
		btn.text = d["text"]
		btn.custom_minimum_size = d.get("min_size", Vector2(160, 60))
		btn.add_theme_font_size_override("font_size", d.get("font_size", 30))
		btn.focus_mode = Control.FOCUS_NONE
		var index := _buttons.size()
		btn.pressed.connect(func() -> void: _activate(index))
		add_child(btn)
		_buttons.append(btn)
		_actions.append(d.get("action", Callable()))
	_apply_highlight()


func _activate(index: int) -> void:
	Sfx.play("click")
	chosen.emit(index)
	var action: Callable = _actions[index]
	if action.is_valid():
		action.call()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			sel = (sel + _buttons.size() - 1) % _buttons.size()
			_apply_highlight()
			get_viewport().set_input_as_handled()
		KEY_RIGHT, KEY_D:
			sel = (sel + 1) % _buttons.size()
			_apply_highlight()
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			get_viewport().set_input_as_handled()
			_activate(sel)


func _apply_highlight() -> void:
	for i in _buttons.size():
		var btn: Button = _buttons[i]
		if i == sel:
			btn.add_theme_stylebox_override("normal", _style_sel)
			btn.add_theme_stylebox_override("hover", _style_sel)
			btn.add_theme_stylebox_override("pressed", _style_sel_pressed)
			btn.add_theme_color_override("font_color", _font_sel)
			btn.add_theme_color_override("font_hover_color", _font_sel)
			btn.add_theme_color_override("font_pressed_color", _font_sel)
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")
			btn.remove_theme_color_override("font_pressed_color")
