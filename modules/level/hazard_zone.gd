extends Area3D
class_name HazardZone
## 环境危险区域基类
## 毒气区、低温区、高温地面等环境危险

@export var hazard_id: String = "haz_gas_zone"
@export var hazard_type: String = "poison"  # poison, cold, heat, acid, electric, slow
@export var damage_per_second: float = 5.0
@export var speed_modifier: float = 1.0  # 1.0 = 正常, 0.5 = 减速50%
@export var status_effect: String = ""  # poison, cold, burn, etc.
@export var immunity_equipment: String = ""  # 免疫此危险的装备subtype
@export var zone_color: Color = Color(0.5, 1.0, 0.5, 0.2)
@export var show_visual: bool = true

var players_in_zone: Array = []
var damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if show_visual:
		_create_visual()

func _process(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= 1.0:
		damage_timer = 0.0
		_apply_damage()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		players_in_zone.append(body)
		# 检查免疫
		if immunity_equipment != "" and body.has_method("has_equipment_immunity"):
			if body.has_equipment_immunity(hazard_type):
				return
		# 应用减速
		if speed_modifier != 1.0 and body.has_method("current_move_speed"):
			pass  # 减速在玩家移动逻辑中处理

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		players_in_zone.erase(body)

func _apply_damage() -> void:
	for player in players_in_zone:
		if player == null or not is_instance_valid(player):
			continue
		# 检查免疫
		if immunity_equipment != "" and player.has_method("has_equipment_immunity"):
			if player.has_equipment_immunity(hazard_type):
				continue
		# 造成伤害
		if player.has_method("take_damage"):
			player.take_damage(damage_per_second, Vector3.ZERO)
		# 屏幕效果
		if hazard_type == "poison":
			# 中毒绿色边缘（简化：用toast提示）
			pass
		elif hazard_type == "cold":
			# 低温蓝色边缘
			pass

func _create_visual() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(10, 0.1, 10)
	mesh.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = zone_color
	mat.transparency = 1
	mat.emission_enabled = true
	mat.emission = zone_color
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position.y = 0.05
	add_child(mesh)
	# 点光源
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = zone_color
	light.light_energy = 1.0
	light.omni_range = 8.0
	light.position.y = 2.0
	add_child(light)

func is_player_in_zone(player: Node) -> bool:
	return players_in_zone.has(player)

func get_speed_modifier() -> float:
	return speed_modifier
