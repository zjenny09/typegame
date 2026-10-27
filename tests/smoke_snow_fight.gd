extends SceneTree
## 冒烟测试：headless 模拟键盘，验证“打雪球”胜利/失败/同屏上限。
## 运行：Godot_console.exe --headless --path . -s res://tests/smoke_snow_fight.gd

const SNOW_SCENE := preload("res://scenes/snowball/snow_fight.tscn")

var failed := false


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame
	# headless 帧率极高而生成节奏按真实时间，统一 10 倍时间加速
	Engine.time_scale = 10.0
	await _run_letters_win()
	if failed:
		return
	await _run_idle_loss()
	if failed:
		return
	await _run_words_win()
	if failed:
		return
	Engine.time_scale = 1.0
	print("SMOKE PASS: 打雪球 胜利与失败全流程通过")
	quit(0)


func _run_letters_win() -> void:
	GameSession.snow_level = 1
	var game := SNOW_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.get("goal") != null, "snow_fight.gd 加载失败（存在解析错误）")
	if failed:
		return
	_check(game.state == game.State.PLAYING, "开局应 PLAYING")
	_check(game._active_count() == 1, "开局应有 1 个雪球")
	_check(game.goal == 20, "字母关目标应为 20")
	if failed:
		game.queue_free()
		return

	# 打错：敲一个屏幕上没有的字母
	var on_screen := {}
	for b in game.balls:
		if not b["dead"]:
			on_screen[b["text"]] = true
	var wrong := "A"
	while on_screen.has(wrong):
		wrong = char(65 + randi() % 26)
	await press(wrong)
	_check(game.mistakes == 1, "打错应记 1 次失误，实际 %d" % game.mistakes)
	_check(game.typed == "", "打错应清空输入缓冲")
	_check(game.smashed == 0, "打错不应击碎雪球")
	if failed:
		game.queue_free()
		return

	# 依次敲最低（最危险）雪球的字母，直到击碎 20 个；无球时等生成
	var deadline := Time.get_ticks_msec() + 120000
	while game.state != game.State.WON and Time.get_ticks_msec() < deadline:
		var lowest: Dictionary = {}
		var ly := -1e9
		for b in game.balls:
			if not b["dead"] and b["y"] > ly:
				ly = b["y"]
				lowest = b
		if lowest.is_empty():
			await process_frame
		else:
			await press(lowest["text"])
	_check(game.state == game.State.WON, "击碎 20 个应获胜")
	_check(game.smashed == 20, "应恰好击碎 20 个，实际 %d" % game.smashed)
	_check(game._active_count() <= 5, "同屏雪球不应超过 5 个")
	_check(game.result_layer.visible, "胜利应显示结算界面")
	game.queue_free()
	await process_frame


func _run_idle_loss() -> void:
	GameSession.snow_level = 1
	var game := SNOW_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	# 不输入，时间加速 20 倍，等第一颗雪球落地（约 8.2s 模拟时间）
	Engine.time_scale = 20.0
	var deadline := Time.get_ticks_msec() + 15000
	while game.state == game.State.PLAYING and Time.get_ticks_msec() < deadline:
		await process_frame
	Engine.time_scale = 10.0
	_check(game.state == game.State.LOST, "雪球落地应判失败")
	_check(game.balls.size() <= 5, "生成的雪球总数不应超过 5，实际 %d" % game.balls.size())
	_check(game.result_layer.visible, "失败应显示结算界面")
	game.queue_free()
	await process_frame


func _run_words_win() -> void:
	GameSession.snow_level = 2
	var game := SNOW_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.get("goal") != null, "snow_fight.gd 加载失败（存在解析错误）")
	if failed:
		return
	_check(game.goal == 12, "单词关目标应为 12")
	var pool: Array = game.word_pool
	_check(pool.size() >= game.goal - 1, "词池应有足够词条（开局首球已消耗 1 个），实际 %d" % pool.size())
	for i in pool.size():
		for j in range(i + 1, pool.size()):
			var a: String = pool[i][0]
			var b: String = pool[j][0]
			_check(not (a.begins_with(b) or b.begins_with(a)),
				"词池不应有前缀冲突：%s / %s" % [a, b])
			if failed:
				game.queue_free()
				return

	# 打错：敲一个没有任何雪球以之开头的字母
	var firsts := {}
	for b in game.balls:
		if not b["dead"]:
			firsts[(b["text"] as String)[0].to_lower()] = true
	var wrong := "a"
	while firsts.has(wrong):
		wrong = char(97 + randi() % 26)
	await press(wrong)
	_check(game.mistakes == 1, "打错应记失误")
	if failed:
		game.queue_free()
		return

	# 逐球完整输入全文（词池无前缀冲突，输入必唯一完成）；无球时等生成
	var deadline := Time.get_ticks_msec() + 120000
	while game.state != game.State.WON and Time.get_ticks_msec() < deadline:
		var target: Dictionary = {}
		for b in game.balls:
			if not b["dead"]:
				target = b
				break
		if target.is_empty():
			await process_frame
		else:
			for ch in (target["text"] as String):
				if game.state != game.State.PLAYING:
					break
				await press(ch)
	_check(game.state == game.State.WON, "击碎 12 个应获胜")
	_check(game.smashed == 12, "应恰好击碎 12 个，实际 %d" % game.smashed)
	_check(game.result_layer.visible, "胜利应显示结算界面")
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
