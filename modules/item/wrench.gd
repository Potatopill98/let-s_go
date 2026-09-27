extends Area3D

# ============================================================
# Wrench Tool
# Can repair doors and mechanisms, cannot attack
# ============================================================

var item_name: String = "扳手"
var item_type: int = 0 # 0=tool, 1=weapon, 2=consumable
var can_attack: bool = false
var can_interact: bool = true
var interact_tag: String = "wrench"
var is_held: bool = false
var holder: Node = null

var player_in_range: bool = false
var wrench_light: OmniLight3D = null
var _model_built: bool = false

func _ready() -> void:
	add_to_group("holdable")
	_build_wrench_model()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact") and not is_held:
		var player: Node = get_tree().get_first_node_in_group("player")
		if player != null:
			player.pick_up_item(self)
			player_in_range = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_held:
		player_in_range = true
		if UIManager != null:
			UIManager.show_interaction_prompt("按E拾取扳手")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	visible = false
	_ensure_light()
	wrench_light.light_energy = 0.0
	# 关闭模型自发光
	for child in get_children():
		if child is MeshInstance3D and child.mesh != null:
			var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				mat.emission_energy_multiplier = 0.0
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	visible = true
	_ensure_light()
	wrench_light.light_energy = 5.0
	# 恢复模型自发光
	for child in get_children():
		if child is MeshInstance3D and child.mesh != null:
			var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
			if mat != null and mat.emission_enabled:
				mat.emission_energy_multiplier = 2.0
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func _ensure_light() -> void:
	# 确保光源存在（pick_up可能在_ready之前被调用）
	if wrench_light == null:
		wrench_light = OmniLight3D.new()
		wrench_light.light_color = Color(0.3, 0.6, 1.0)
		wrench_light.omni_range = 8.0
		wrench_light.position.y = 0.3
		add_child(wrench_light)

func _build_wrench_model() -> void:
	if _model_built:
		return
	_model_built = true
	# 发光提示（地上时亮，拾取后灭）
	if wrench_light == null:
		wrench_light = OmniLight3D.new()
		wrench_light.light_color = Color(0.3, 0.6, 1.0)
		wrench_light.light_energy = 5.0
		wrench_light.omni_range = 8.0
		wrench_light.position.y = 0.3
		add_child(wrench_light)
	# Handle
	var handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: CylinderMesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.035
	handle_mesh.height = 0.4
	var handle_mat: StandardMaterial3D = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.2, 0.5, 0.9)
	handle_mat.roughness = 0.4
	handle_mat.emission_enabled = true
	handle_mat.emission = Color(0.2, 0.5, 1.0)
	handle_mat.emission_energy_multiplier = 2.0
	handle_mesh.material = handle_mat
	handle.mesh = handle_mesh
	handle.rotation.x = deg_to_rad(90)
	handle.position.z = 0.1
	add_child(handle)
	# Wrench head
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.12, 0.04, 0.08)
	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.7, 0.7, 0.75)
	head_mat.metallic = 0.8
	head_mat.roughness = 0.3
	head_mesh.material = head_mat
	head.mesh = head_mesh
	head.position.z = -0.15
	add_child(head)
