extends StaticBody3D
class_name SecurityDoor
## 安全门
## 需要电力恢复 + 门禁卡才能打开

@export var door_name: String = "安全门"
@export var required_keycard: String = "task_keycard_lab"
@export var open_speed: float = 3.0
@export var open_distance: float = 5.0
@export var open_direction: Vector3 = Vector3.UP

var is_opening: bool = false
var is_open: bool = false
var is_powered: bool = false
var original_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var interaction_area: Area3D = null
var player_inside: Node = null
var status_light: OmniLight3D = null

func _ready() -> void:
	add_to_group("security_door")
	original_position = position
	target_position = original_position + open_direction.normalized() * open_distance
	_build_visual()
	_build_interaction_area()
	# 监听电力恢复信号
	var pm: Node = get_node_or_null("/root/PowerManager")
	if pm != null:
		pm.power_restored.connect(_on_power_restored)
		is_powered = pm.get_power_status()

func _process(delta: float) -> void:
	if is_opening and not is_open:
		position = position.move_toward(target_position, open_speed * delta)
		if position.distance_to(target_position) < 0.01:
			is_open = true
			is_opening = false
			if collision_shape != null:
				collision_shape.disabled = true
	# 检测E键刷卡
	if player_inside != null and not is_open and not is_opening:
		if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
			try_open()

func _build_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(4.0, 4.0, 0.3)
	mesh_instance.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.35, 0.4, 1)
	mesh_instance.material_override = mat
	mesh_instance.position.y = 2.0
	add_child(mesh_instance)
	# 状态灯
	status_light = OmniLight3D.new()
	status_light.light_color = Color(1, 0.2, 0.2)  # 红色=未通电/未开
	status_light.light_energy = 2.0
	status_light.omni_range = 6.0
	status_light.position = Vector3(0, 3.5, 0.5)
	add_child(status_light)
	# 碰撞
	collision_shape = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4.0, 4.0, 0.3)
	collision_shape.shape = shape
	collision_shape.position.y = 2.0
	add_child(collision_shape)

func _build_interaction_area() -> void:
	interaction_area = Area3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(5.0, 4.0, 3.0)
	col.shape = shape
	col.position.y = 2.0
	interaction_area.add_child(col)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	add_child(interaction_area)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_open:
		player_inside = body
		_update_prompt()

func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _update_prompt() -> void:
	if UIManager == null:
		return
	if not is_powered:
		UIManager.show_interaction_prompt("大门未通电，需要修复发电机")
	elif player_inside != null and not player_inside.has_method("has_task_item") or not player_inside.has_task_item(required_keycard):
		UIManager.show_interaction_prompt("需要门禁卡")
	else:
		UIManager.show_interaction_prompt("按E刷卡开门")

func try_open() -> void:
	if is_open or is_opening:
		return
	if not is_powered:
		if UIManager != null:
			UIManager.show_toast("大门未通电！")
		return
	if player_inside == null:
		return
	if not player_inside.has_method("has_task_item") or not player_inside.has_task_item(required_keycard):
		if UIManager != null:
			UIManager.show_toast("需要门禁卡！")
		return
	# 开门
	is_opening = true
	if status_light != null:
		status_light.light_color = Color(0.2, 1, 0.3)  # 绿色=已开
	if UIManager != null:
		UIManager.hide_interaction_prompt()
		UIManager.show_toast("门禁验证通过，大门开启")

func _on_power_restored() -> void:
	is_powered = true
	if status_light != null:
		status_light.light_color = Color(1, 0.8, 0.2)  # 黄色=通电但未开
	if player_inside != null:
		_update_prompt()
	if UIManager != null:
		UIManager.show_toast("大门已通电")
