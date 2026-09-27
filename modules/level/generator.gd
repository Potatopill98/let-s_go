extends StaticBody3D
class_name Generator
## 发电机
## 需要用扳手维修，修好后提供电力

@export var generator_id: String = "generator_1"
@export var generator_name: String = "发电机"
@export var repair_time: float = 5.0
@export var requires_tool: String = "wrench"  # 需要的工具

var is_repaired: bool = false
var is_being_repaired: bool = false
var repair_progress: float = 0.0
var mesh_instance: MeshInstance3D = null
var interaction_area: Area3D = null
var player_inside: Node = null
var status_light: OmniLight3D = null

func _ready() -> void:
	add_to_group("generator")
	_build_visual()
	_build_interaction_area()
	# 注册到电力管理器
	var pm: Node = get_node_or_null("/root/PowerManager")
	if pm != null:
		pm.register_generator(generator_id)

func _process(delta: float) -> void:
	# 检测E键开始维修
	if player_inside != null and not is_repaired and not is_being_repaired:
		if Input.is_action_pressed("interact") or Input.is_key_pressed(KEY_E):
			# 检查是否有扳手
			if player_inside.has_method("has_held_item") and player_inside.has_held_item(requires_tool):
				start_repair()
			else:
				if UIManager != null:
					UIManager.show_toast("需要扳手才能维修")
	if is_being_repaired and player_inside != null:
		repair_progress += delta / repair_time
		if UIManager != null:
			UIManager.update_progress(repair_progress * 100, 100)
		if repair_progress >= 1.0:
			_finish_repair()
	elif not is_being_repaired and repair_progress > 0 and not is_repaired:
		# 松开E键，进度回退
		repair_progress = max(0, repair_progress - delta * 0.5)
		if UIManager != null:
			UIManager.hide_progress()

func _build_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.5, 1.2, 1.0)
	mesh_instance.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5, 1)
	mesh_instance.material_override = mat
	mesh_instance.position.y = 0.6
	add_child(mesh_instance)
	# 状态灯
	status_light = OmniLight3D.new()
	status_light.light_color = Color(1, 0.2, 0.2)  # 红色=未修好
	status_light.light_energy = 2.0
	status_light.omni_range = 5.0
	status_light.position = Vector3(0, 1.5, 0)
	add_child(status_light)
	# 碰撞
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.2, 1.0)
	col.shape = shape
	col.position.y = 0.6
	add_child(col)

func _build_interaction_area() -> void:
	interaction_area = Area3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 2.5
	col.shape = shape
	col.position.y = 1.0
	interaction_area.add_child(col)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	add_child(interaction_area)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_repaired:
		player_inside = body
		if UIManager != null:
			UIManager.show_interaction_prompt("按住E维修发电机（需要扳手）")

func _on_body_exited(body: Node) -> void:
	if body == player_inside:
		player_inside = null
		is_being_repaired = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()
			UIManager.hide_progress()

func start_repair() -> void:
	if is_repaired or player_inside == null:
		return
	is_being_repaired = true
	if UIManager != null:
		UIManager.show_progress(0, 100, "维修发电机中...")

func _finish_repair() -> void:
	is_repaired = true
	is_being_repaired = false
	repair_progress = 1.0
	if UIManager != null:
		UIManager.hide_progress()
	# 状态灯变绿
	if status_light != null:
		status_light.light_color = Color(0.2, 1, 0.3)
	# 通知电力管理器
	var pm2: Node = get_node_or_null("/root/PowerManager")
	if pm2 != null:
		pm2.generator_repaired(generator_id)
	# UI
	if UIManager != null:
		UIManager.hide_progress()
		UIManager.hide_interaction_prompt()
		UIManager.show_toast(generator_name + " 维修完成")
