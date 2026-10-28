extends SceneTree
## 冒烟测试：音效合成与存档系统。
## 运行：Godot_console.exe --headless --path . -s res://tests/smoke_save_sfx.gd

var failed := false


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame

	# —— 音效：全部预置音效应成功合成且数据非空 ——
	for sfx_name in ["type", "click", "move", "confirm", "wrong", "jump", "splash",
			"step", "pop", "firework", "win", "lose", "thud"]:
		var s: AudioStreamWAV = Sfx.stream(sfx_name)
		_check(s != null and s.data.size() >= 100, "音效 %s 合成失败" % sfx_name)
		if failed:
			return
	# 未知名应回退到默认音
	_check(Sfx.stream("not_exists") != null, "未知音效应回退默认")
	print("SFX OK: 13 种音效合成通过")

	# —— 存档：使用独立测试文件，不污染正式存档 ——
	SaveStore.path = "user://test_save_smoke.json"
	var abs_path := ProjectSettings.globalize_path(SaveStore.path)
	if FileAccess.file_exists(SaveStore.path):
		DirAccess.remove_absolute(abs_path)
	SaveStore.reload_from_disk()

	_check(SaveStore.best("frog", 1).is_empty(), "空存档应无记录")
	_check(SaveStore.record_result("frog", 1, 3, 52, 0), "首次记录应刷新最佳")
	_check(not SaveStore.record_result("frog", 1, 2, 10, 0), "更低星不应覆盖最佳")
	var b: Dictionary = SaveStore.best("frog", 1)
	_check(int(b.get("stars", 0)) == 3 and int(b.get("time", 0)) == 52,
		"低星记录后最佳应保持 3 星 52 秒")
	_check(SaveStore.record_result("frog", 1, 3, 40, 0), "同星更快应刷新最佳")
	_check(int(SaveStore.best("frog", 1).get("time", 0)) == 40, "同星更快后用时应为 40 秒")
	_check(SaveStore.record_result("cop", 1, 1, 70, 5), "另一游戏应独立记录")
	_check(SaveStore.best("cop", 2).is_empty(), "未记录的关卡应无最佳")
	SaveStore.reload_from_disk()
	_check(int(SaveStore.best("frog", 1).get("time", 0)) == 40, "存档应持久化到磁盘")
	_check(int(SaveStore.best("cop", 1).get("stars", 0)) == 1, "cop 记录应持久化")
	if failed:
		return

	# 清理测试文件并恢复正式存档路径
	DirAccess.remove_absolute(abs_path)
	SaveStore.path = SaveStore.DEFAULT_PATH
	SaveStore.reload_from_disk()
	print("SMOKE PASS: 音效合成与存档系统通过")
	quit(0)


func _check(condition: bool, message: String) -> void:
	if failed or condition:
		return
	failed = true
	printerr("SMOKE FAIL: " + message)
	quit(1)
