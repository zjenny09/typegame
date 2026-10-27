extends SceneTree
## 冒烟测试：headless 模拟键盘，验证“警察抓小偷”胜利与失败全流程。
## 运行：Godot_console.exe --headless --path . -s res://tests/smoke_cop_chase.gd

const COP_SCENE := preload("res://scenes/cops_robber/cop_chase.tscn")

var failed := false


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame
	await _run_letters_catch()
	if failed:
		return
	await _run_words_catch()
	if failed:
		return
	await _run_escape_loss()
	if failed:
		return
	print("SMOKE PASS: 警察抓小偷 胜利与失败全流程通过")
	quit(0)


func _run_letters_catch() -> void:
	GameSession.cop_level = 1
	var game := COP_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	_check(game.police_steps == 0.0, "开局警察应在 0 步")
	_check(game.thief_steps == 3.0, "字母关开局小偷应领先 3 步，实际 %s" % game.thief_steps)
	_check(game.targets.size() == 3, "开局应有 3 块目标牌")
	if failed:
		game.queue_free()
		return

	var first: String = game.targets[0]["text"]
	var wrong := "A" if first != "A" else "B"
	await press(wrong)
	_check(game.mistakes == 1, "打错应记 1 次失误")
	_check(game.police_steps == 0.0, "打错警察不应前进")
	_check(game.typed_len == 0, "打错后应清空重输")
	if failed:
		game.queue_free()
		return

	await press(first)
	_check(game.police_steps == 1.0, "打对应追进一步，实际 %s" % game.police_steps)
	_check(game.next_target == 1, "应推进到下一块牌子")
	if failed:
		game.queue_free()
		return

	# 快速连打，验证可以提前追上小偷
	var guard := 0
	while game.state != game.State.WON and guard < 80:
		if game.next_target < game.targets.size():
			for ch in (game.targets[game.next_target]["text"] as String):
				await press(ch)
		else:
			await process_frame
		guard += 1
	_check(game.state == game.State.WON, "打字快应提前追上小偷")
	_check(game.police_steps >= game.thief_steps, "胜利时警察应追平小偷")
	_check(game.result_layer.visible, "胜利应显示结算界面")
	game.queue_free()
	await process_frame


func _run_words_catch() -> void:
	GameSession.cop_level = 2
	var game := COP_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	_check(game.thief_steps == 2.0, "单词关开局小偷应领先 2 步，实际 %s" % game.thief_steps)
	var valid := {}
	for entry in WordBank.WORDS:
		valid[entry[0]] = true
	for t in game.targets:
		_check(valid.has(t["text"]), "单词关目标应来自词库：%s" % t["text"])
	if failed:
		game.queue_free()
		return

	var guard := 0
	while game.state != game.State.WON and guard < 80:
		if game.next_target < game.targets.size():
			for ch in (game.targets[game.next_target]["text"] as String):
				await press(ch)
		else:
			await process_frame
		guard += 1
	_check(game.state == game.State.WON, "单词关连对 2 词应追平小偷")
	_check(game.result_layer.visible, "胜利应显示结算界面")
	game.queue_free()
	await process_frame


func _run_escape_loss() -> void:
	GameSession.cop_level = 1
	var game := COP_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	# 不输入，时间加速 20 倍，等小偷跑到逃脱点（(22-3)*2.4s ≈ 2.3s 实际）
	Engine.time_scale = 20.0
	var deadline := Time.get_ticks_msec() + 15000
	while game.state != game.State.LOST and Time.get_ticks_msec() < deadline:
		await process_frame
	Engine.time_scale = 1.0
	_check(game.state == game.State.LOST, "小偷到逃脱点应判失败")
	_check(game.thief_steps >= game.track_len, "失败时小偷应到达逃脱点")
	_check(game.result_layer.visible, "失败应显示结算界面")
	game.queue_free()
	await process_frame


func press(letter: String) -> void:
	var code := KEY_A + (letter.to_upper().unicode_at(0) - "A".unicode_at(0))
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if failed or condition:
		return
	failed = true
	printerr("SMOKE FAIL: " + message)
	quit(1)
