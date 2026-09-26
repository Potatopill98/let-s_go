extends Node
## 穿戴装备管理器
## 三个槽位：头部、身体、脚部
## 管理装备效果：减伤、免疫、移速修正等

const SLOT_HEAD: int = 0
const SLOT_BODY: int = 1
const SLOT_FEET: int = 2

# 装备数据：每个槽位存储 item_id，空为 ""
var equipped: Array = ["", "", ""]

# 信号
signal equipment_changed(slot: int, item_id: String)

# ==================== 装备/卸下 ====================
func equip(item_id: String) -> bool:
	if not ItemManager.has_item(item_id):
		push_warning("[Equipment] 未知道具：" + item_id)
		return false
	var data: Dictionary = ItemManager.get_item_data(item_id)
	if data.get("item_type", "") != "wearable":
		push_warning("[Equipment] 不是穿戴装备：" + item_id)
		return false
	var slot: int = _get_slot_from_subtype(data.get("item_subtype", ""))
	if slot < 0:
		return false
	equipped[slot] = item_id
	emit_signal("equipment_changed", slot, item_id)
	return true

func unequip(slot: int) -> String:
	if slot < 0 or slot >= 3:
		return ""
	var item_id: String = equipped[slot]
	equipped[slot] = ""
	emit_signal("equipment_changed", slot, "")
	return item_id

func unequip_by_id(item_id: String) -> bool:
	for i in range(3):
		if equipped[i] == item_id:
			equipped[i] = ""
			emit_signal("equipment_changed", i, "")
			return true
	return false

func get_equipped(slot: int) -> String:
	if slot < 0 or slot >= 3:
		return ""
	return equipped[slot]

func is_equipped(item_id: String) -> bool:
	for i in range(3):
		if equipped[i] == item_id:
			return true
	return false

# ==================== 效果计算 ====================
func get_damage_resistance() -> float:
	var resist: float = 0.0
	for i in range(3):
		if equipped[i] == "":
			continue
		var data: Dictionary = ItemManager.get_item_data(equipped[i])
		resist += data.get("damage_resist", 0.0)
	return min(resist, 0.8)  # 最高减伤80%

func get_headshot_resistance() -> float:
	if equipped[SLOT_HEAD] == "":
		return 0.0
	var data: Dictionary = ItemManager.get_item_data(equipped[SLOT_HEAD])
	return data.get("headshot_resist", 0.0)

func get_speed_modifier() -> float:
	var mod: float = 1.0
	for i in range(3):
		if equipped[i] == "":
			continue
		var data: Dictionary = ItemManager.get_item_data(equipped[i])
		var penalty: float = data.get("speed_penalty", 0.0)
		mod -= penalty
		var bonus: float = data.get("speed_bonus", 0.0)
		mod += bonus
	return max(mod, 0.5)  # 最低移速50%

func has_immunity(status_type: String) -> bool:
	for i in range(3):
		if equipped[i] == "":
			continue
		var data: Dictionary = ItemManager.get_item_data(equipped[i])
		var immunities: Array = data.get("immunity", [])
		if status_type in immunities:
			return true
	return false

func has_night_vision() -> bool:
	if equipped[SLOT_HEAD] == "":
		return false
	var data: Dictionary = ItemManager.get_item_data(equipped[SLOT_HEAD])
	return data.get("night_vision", false)

func get_stealth_multiplier() -> float:
	var mult: float = 1.0
	for i in range(3):
		if equipped[i] == "":
			continue
		var data: Dictionary = ItemManager.get_item_data(equipped[i])
		mult *= data.get("stealth_mult", 1.0)
	return mult

func get_vision_penalty() -> float:
	if equipped[SLOT_HEAD] == "":
		return 0.0
	var data: Dictionary = ItemManager.get_item_data(equipped[SLOT_HEAD])
	return data.get("vision_penalty", 0.0)

# ==================== 工具方法 ====================
func _get_slot_from_subtype(subtype: String) -> int:
	match subtype:
		"head": return SLOT_HEAD
		"body": return SLOT_BODY
		"feet": return SLOT_FEET
	return -1

func clear() -> void:
	equipped = ["", "", ""]
	for i in range(3):
		emit_signal("equipment_changed", i, "")

func get_save_data() -> Dictionary:
	return {"equipped": equipped.duplicate()}

func load_save_data(data: Dictionary) -> void:
	equipped = data.get("equipped", ["", "", ""]).duplicate()
	for i in range(3):
		emit_signal("equipment_changed", i, equipped[i])

func get_equipment_list() -> Array:
	var result: Array = []
	for i in range(3):
		if equipped[i] != "":
			result.append({"slot": i, "item_id": equipped[i], "name": ItemManager.get_item_name(equipped[i])})
	return result
