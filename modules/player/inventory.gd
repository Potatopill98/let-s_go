extends Node
class_name Inventory
## 背包系统组件
## 6格背包：2任务格 + 4消耗品格
## 任务格：放门禁卡、钥匙等，不可丢弃
## 消耗品格：放医疗包、弹药等，可堆叠，数字键1-4使用

# 背包数据：每个元素是 {item_id: String, count: int}，空槽为 {}
var task_slots: Array = [{}, {}, {}, {}]  # 前2格是任务格，预留4格但只用前2
var consumable_slots: Array = [{}, {}, {}, {}]  # 4格消耗品

# 信号
signal inventory_changed
signal item_used(item_id: String, slot_index: int)
signal task_item_added(item_id: String)
signal inventory_full(item_type: String)

# ==================== 任务道具 ====================
func add_task_item(item_id: String) -> bool:
	# 检查是否已有
	for i in range(2):
		if task_slots[i].get("item_id", "") == item_id:
			return true  # 已有，不重复添加
	# 找空槽
	for i in range(2):
		if task_slots[i].is_empty():
			task_slots[i] = {"item_id": item_id, "count": 1}
			emit_signal("task_item_added", item_id)
			emit_signal("inventory_changed")
			return true
	emit_signal("inventory_full", "task")
	return false

func has_task_item(item_id: String) -> bool:
	for i in range(2):
		if task_slots[i].get("item_id", "") == item_id:
			return true
	return false

func remove_task_item(item_id: String) -> bool:
	for i in range(2):
		if task_slots[i].get("item_id", "") == item_id:
			task_slots[i] = {}
			emit_signal("inventory_changed")
			return true
	return false

func get_task_items() -> Array:
	var result: Array = []
	for i in range(2):
		if not task_slots[i].is_empty():
			result.append(task_slots[i])
	return result

# ==================== 消耗品 ====================
func add_consumable(item_id: String, count: int = 1) -> bool:
	if not ItemManager.has_item(item_id):
		push_warning("[Inventory] 未知道具：" + item_id)
		return false
	var data: Dictionary = ItemManager.get_item_data(item_id)
	var max_stack: int = data.get("max_stack", 1)
	var stackable: bool = data.get("stackable", false)

	# 先尝试堆叠到已有槽
	if stackable:
		for i in range(4):
			var slot: Dictionary = consumable_slots[i]
			if slot.get("item_id", "") == item_id:
				var current_count: int = slot.get("count", 0)
				if current_count < max_stack:
					var add_count: int = min(count, max_stack - current_count)
					slot["count"] = current_count + add_count
					count -= add_count
					if count <= 0:
						emit_signal("inventory_changed")
						return true

	# 找空槽
	for i in range(4):
		if consumable_slots[i].is_empty():
			var add_count: int = min(count, max_stack)
			consumable_slots[i] = {"item_id": item_id, "count": add_count}
			count -= add_count
			if count <= 0:
				emit_signal("inventory_changed")
				return true

	emit_signal("inventory_full", "consumable")
	emit_signal("inventory_changed")
	return count <= 0

func use_consumable(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= 4:
		return {}
	var slot: Dictionary = consumable_slots[slot_index]
	if slot.is_empty():
		return {}
	var item_id: String = slot.get("item_id", "")
	var data: Dictionary = ItemManager.get_item_data(item_id)

	# 减少数量
	var count: int = slot.get("count", 1)
	count -= 1
	if count <= 0:
		consumable_slots[slot_index] = {}
	else:
		slot["count"] = count

	emit_signal("item_used", item_id, slot_index)
	emit_signal("inventory_changed")
	return data

func get_consumable(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= 4:
		return {}
	return consumable_slots[slot_index]

func get_consumable_count(item_id: String) -> int:
	var total: int = 0
	for i in range(4):
		if consumable_slots[i].get("item_id", "") == item_id:
			total += consumable_slots[i].get("count", 0)
	return total

func remove_consumable(item_id: String, count: int = 1) -> bool:
	var remaining: int = count
	for i in range(4):
		if remaining <= 0:
			break
		if consumable_slots[i].get("item_id", "") == item_id:
			var slot_count: int = consumable_slots[i].get("count", 0)
			var take: int = min(remaining, slot_count)
			slot_count -= take
			remaining -= take
			if slot_count <= 0:
				consumable_slots[i] = {}
			else:
				consumable_slots[i]["count"] = slot_count
	emit_signal("inventory_changed")
	return remaining <= 0

# ==================== 通用 ====================
func clear() -> void:
	task_slots = [{}, {}, {}, {}]
	consumable_slots = [{}, {}, {}, {}]
	emit_signal("inventory_changed")

func is_consumable_full() -> bool:
	for i in range(4):
		if consumable_slots[i].is_empty():
			return false
	return true

func is_task_full() -> bool:
	for i in range(2):
		if task_slots[i].is_empty():
			return false
	return true

func get_save_data() -> Dictionary:
	return {
		"task_slots": task_slots.duplicate(),
		"consumable_slots": consumable_slots.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	task_slots = data.get("task_slots", [{}, {}, {}, {}]).duplicate()
	consumable_slots = data.get("consumable_slots", [{}, {}, {}, {}]).duplicate()
	emit_signal("inventory_changed")
