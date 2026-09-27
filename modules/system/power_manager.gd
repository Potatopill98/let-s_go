extends Node
## 电力管理器
## 跟踪所有发电机状态，全部修好后触发通电

var generators: Dictionary = {}  # generator_id -> is_repaired
var total_generators: int = 0
var repaired_count: int = 0
var is_powered: bool = false

signal power_restored()  # 通电信号

func _ready() -> void:
	add_to_group("power_manager")

func register_generator(generator_id: String) -> void:
	if not generators.has(generator_id):
		generators[generator_id] = false
		total_generators += 1

func generator_repaired(generator_id: String) -> void:
	if generators.has(generator_id) and not generators[generator_id]:
		generators[generator_id] = true
		repaired_count += 1
		# 检查是否全部修好
		if repaired_count >= total_generators and total_generators > 0:
			_restore_power()

func _restore_power() -> void:
	if is_powered:
		return
	is_powered = true
	power_restored.emit()
	if UIManager != null:
		UIManager.show_toast("电力已恢复！大门已通电")
	# 全局灯光变亮
	var lights: Array = get_tree().get_nodes_in_group("emergency_light")
	for light in lights:
		if light is OmniLight3D:
			light.light_color = Color(1, 1, 1)
			light.light_energy = 2.0

func get_power_status() -> bool:
	return is_powered

func get_repaired_count() -> int:
	return repaired_count

func get_total_generators() -> int:
	return total_generators

func reset() -> void:
	generators.clear()
	total_generators = 0
	repaired_count = 0
	is_powered = false
