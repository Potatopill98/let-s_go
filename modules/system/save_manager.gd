extends Node
## 存档管理器
## 全局自动加载，负责存档/读档/中场休息

const SAVE_PATH: String = "user://savegame.save"
const SAVE_VERSION: int = 1

var current_save: Dictionary = {}
var has_save: bool = false

func _ready() -> void:
	load_save()

## 创建新存档
func new_save() -> void:
	current_save = {
		"version": SAVE_VERSION,
		"player_health": 100,
		"player_max_health": 100,
		"current_level": 0,
		"inventory": [],
		"equipment": {},
		"unlocked_weapons": [],
		"play_time": 0,
		"deaths": 0,
		"kills": 0,
		"timestamp": Time.get_datetime_string_from_system(),
	}
	has_save = true
	save_game()

## 保存游戏
func save_game(extra_data: Dictionary = {}) -> void:
	current_save["timestamp"] = Time.get_datetime_string_from_system()
	# 合并额外数据
	for key in extra_data.keys():
		current_save[key] = extra_data[key]
	# 写入文件
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法打开存档文件: " + SAVE_PATH)
		return
	file.store_var(current_save)
	file.close()
	has_save = true

## 读取存档
func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		has_save = false
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取存档文件: " + SAVE_PATH)
		return false
	current_save = file.get_var(true) as Dictionary
	file.close()
	# 检查版本
	if current_save.get("version", 0) != SAVE_VERSION:
		push_warning("存档版本不匹配，创建新存档")
		new_save()
		return false
	has_save = true
	return true

## 删除存档
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		FileAccess.remove(SAVE_PATH)
	current_save = {}
	has_save = false

## 获取存档数据
func get_save_data() -> Dictionary:
	return current_save

## 设置玩家数据
func set_player_data(health: float, max_health: float, level: int) -> void:
	current_save["player_health"] = health
	current_save["player_max_health"] = max_health
	current_save["current_level"] = level

## 设置背包数据
func set_inventory_data(inventory_data: Array) -> void:
	current_save["inventory"] = inventory_data

## 设置装备数据
func set_equipment_data(equipment_data: Dictionary) -> void:
	current_save["equipment"] = equipment_data

## 增加游戏时间
func add_play_time(seconds: float) -> void:
	current_save["play_time"] = current_save.get("play_time", 0) + seconds

## 增加死亡数
func add_death() -> void:
	current_save["deaths"] = current_save.get("deaths", 0) + 1

## 增加击杀数
func add_kill() -> void:
	current_save["kills"] = current_save.get("kills", 0) + 1

## 获取格式化的游戏时间
func get_formatted_play_time() -> String:
	var total_seconds: int = int(current_save.get("play_time", 0))
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

## 检查是否有存档
func has_save_file() -> bool:
	return has_save

## 获取存档信息摘要
func get_save_summary() -> String:
	if not has_save:
		return "无存档"
	var summary: String = "关卡: " + str(current_save.get("current_level", 0))
	summary += " | 生命: " + str(current_save.get("player_health", 100)) + "/" + str(current_save.get("player_max_health", 100))
	summary += " | 时间: " + get_formatted_play_time()
	summary += " | 击杀: " + str(current_save.get("kills", 0))
	summary += " | 死亡: " + str(current_save.get("deaths", 0))
	return summary
