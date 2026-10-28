class_name SaveStore
extends RefCounted
## 本地存档：每个游戏每关的最佳星级/用时/失误，持久化到 user://save.json。
## 全部静态接口：SaveStore.record_result(...) / SaveStore.best(...)。

const DEFAULT_PATH := "user://save.json"

static var path := DEFAULT_PATH
static var _data: Dictionary = {"version": 1, "best": {}}


static func reload_from_disk() -> void:
	_data = {"version": 1, "best": {}}
	var exists := FileAccess.file_exists(path)
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := "" if f == null else f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	print("[SaveStore] load path=", path, " exists=", exists, " len=", txt.length(),
		" type=", typeof(parsed))
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("best") \
			and typeof(parsed["best"]) == TYPE_DICTIONARY:
		_data = parsed


static func best(game_id: String, level: int) -> Dictionary:
	var rec: Variant = _data["best"].get("%s_%d" % [game_id, level], {})
	return rec if typeof(rec) == TYPE_DICTIONARY else {}


## 记录一次胜利结算。返回是否刷新个人最佳（星级更高，或同星用时更短）。
static func record_result(game_id: String, level: int, stars: int, elapsed: int, mistakes: int) -> bool:
	var key := "%s_%d" % [game_id, level]
	var prev := best(game_id, level)
	var better := prev.is_empty() \
		or stars > int(prev.get("stars", 0)) \
		or (stars == int(prev.get("stars", 0)) and elapsed < int(prev.get("time", 1 << 30)))
	if better:
		_data["best"][key] = {"stars": stars, "time": elapsed, "mistakes": mistakes}
		_save()
	return better


static func _save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_data, "  "))
