extends SceneTree
## 冒烟测试：headless 模拟键盘，完整通关“小青蛙过河”字母关与单词关。
## 运行：Godot_console.exe --headless --path . -s res://tests/smoke_frog_river.gd

const FROG_SCENE := preload("res://scenes/frog_river/frog_river.tscn")

var failed := false


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame
	await _run_letters_level()
	if failed:
		return
	await _run_words_level()
	if failed:
		return
	print("SMOKE PASS: 小青蛙过河 字母关与单词关全流程通过")
	quit(0)


func _run_letters_level() -> void:
	GameSession.frog_level = GameSession.FrogLevel.LETTERS
	var game := FROG_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	_check(game.pads.size() == 6, "字母关应有 6 片荷叶")
	if failed:
		game.queue_free()
		return
	var seen := {}
	for pad in game.pads:
		var t: String = pad["text"]
		_check(t.length() == 1 and t.to_upper() == t, "字母关荷叶应为单个大写字母：%s" % t)
		seen[t] = true
	_check(seen.size() == 6, "字母关 6 个字母应互不相同，实际 %s" % [seen.keys()])
	_check(game.state == game.State.PLAYING, "开局应为 PLAYING 状态")
	if failed:
		game.queue_free()
		return

	# 先打错一个键：应提示重输、不推进、不刷新字母
	var first: String = game.pads[0]["text"]
	var wrong := "A" if first != "A" else "B"
	await press_key(wrong)
	_check(game.mistakes == 1, "打错应记 1 次失误，实际 %d" % game.mistakes)
	_check(game.next_target == 0, "打错不应推进荷叶")
	_check(game.typed_len == 0, "打错后应清空重输")
	_check(game.pads[0]["text"] == first, "打错不应刷新待输入字母")
	if failed:
		game.queue_free()
		return

	# 依次打对 6 片荷叶，最后一跳到达对岸进入胜利
	await press_key(first)
	for i in range(1, 6):
		await _wait_land(game)
		if failed:
			game.queue_free()
			return
		_check(game.next_target == i, "应推进到第 %d 片荷叶，实际 %d" % [i, game.next_target])
		if failed:
			game.queue_free()
			return
		for ch in (game.pads[i]["text"] as String):
			await press_key(ch)
	await _wait_win(game)
	if not failed:
		_check(game.win_layer.visible, "通关后应显示胜利界面")
		_check(game.mistakes == 1, "字母关应恰好 1 次失误，实际 %d" % game.mistakes)
	game.queue_free()
	await process_frame


func _run_words_level() -> void:
	GameSession.frog_level = GameSession.FrogLevel.WORDS
	var game := FROG_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	_check(game.pads.size() == 6, "单词关应有 6 片荷叶")
	var valid := {}
	for entry in WordBank.WORDS:
		valid[entry[0]] = true
	for pad in game.pads:
		var t: String = pad["text"]
		_check(valid.has(t), "单词关词汇应来自词库：%s" % t)
		_check((pad["zh"] as String) != "", "单词关应带中文释义")
		_check(t.length() <= 8, "单词长度应便于显示：%s" % t)
	if failed:
		game.queue_free()
		return

	for i in 6:
		var word: String = game.pads[i]["text"]
		var before: int = game.mistakes
		# 每片荷叶先打错一个字符，验证重输规则
		var wrong_char := "a" if word[0].to_lower() != "a" else "b"
		await press_key(wrong_char)
		_check(game.mistakes == before + 1, "第 %d 片荷叶打错应记失误" % (i + 1))
		_check(game.next_target == i, "打错不应推进荷叶")
		_check(game.typed_len == 0, "单词打错应从头重输")
		if failed:
			game.queue_free()
			return
		for ch in word:
			await press_key(ch)
		await _wait_land(game)
		if failed:
			game.queue_free()
			return
		if i < 5:
			_check(game.next_target == i + 1, "第 %d 片荷叶应通过" % (i + 1))
			if failed:
				game.queue_free()
				return
	await _wait_win(game)
	if not failed:
		_check(game.win_layer.visible, "单词关通关后应显示胜利界面")
	game.queue_free()
	await process_frame


func press_key(letter: String) -> void:
	var code := KEY_A + (letter.to_upper().unicode_at(0) - "A".unicode_at(0))
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame


func _wait_land(game: Node) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while game.state == game.State.JUMPING and Time.get_ticks_msec() < deadline:
		await process_frame
	if game.state == game.State.JUMPING:
		_check(false, "等待跳跃落地超时")


func _wait_win(game: Node) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while game.state != game.State.WON and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(game.state == game.State.WON, "等待游戏胜利超时")


func _check(condition: bool, message: String) -> void:
	if failed or condition:
		return
	failed = true
	printerr("SMOKE FAIL: " + message)
	quit(1)
