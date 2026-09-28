extends Area3D

# ============================================================
# Flashlight Tool - 逃生游戏风格手电筒
# 手持时：锥形光束向前照亮（跟随视角），无全向圆光
# 地上时：微弱发光方便找到
# 参考 Escape the Backrooms 等逃生游戏
# ============================================================

var item_name: String = "手电筒"
var item_type: int = 0
var can_attack: bool = false
var can_interact: bool = false
var interact_tag: String = ""
var is_held: bool = false
var holder: Node = null

var player_in_range: bool = false
var light_spot: SpotLight3D = null
var ground_glow: OmniLight3D = null
var _model_built: bool = false
var _mesh_nodes: Array = []

func _ready() -> void:
	add_to_group("holdable")
	_build_flashlight_model()
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
			UIManager.show_interaction_prompt("按E拾取手电筒")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()

func _ensure_lights() -> void:
	if light_spot == null:
		light_spot = SpotLight3D.new()
		light_spot.light_color = Color(1.0, 0.97, 0.88)
		light_spot.spot_range = 14.0
		light_spot.spot_angle = 32.0
		light_spot.spot_attenuation = 1.3
		light_spot.rotation.x = 0.0
		light_spot.position = Vector3(0, 0.12, -0.45)
		add_child(light_spot)
	if ground_glow == null:
		ground_glow = OmniLight3D.new()
		ground_glow.light_color = Color(1.0, 0.97, 0.85)
		ground_glow.omni_range = 2.5
		ground_glow.position.y = 0.3
		add_child(ground_glow)

func _set_meshes_visible(vis: bool) -> void:
	for m in _mesh_nodes:
		if is_instance_valid(m):
			m.visible = vis

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	_ensure_lights()
	_set_meshes_visible(false)
	light_spot.light_energy = 2.8
	ground_glow.light_energy = 0.0
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	_ensure_lights()
	_set_meshes_visible(true)
	light_spot.light_energy = 0.2
	ground_glow.light_energy = 1.2
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func _build_flashlight_model() -> void:
	if _model_built:
		return
	_model_built = true
	_ensure_lights()
	if is_held:
		light_spot.light_energy = 2.8
		ground_glow.light_energy = 0.0
	else:
		light_spot.light_energy = 0.2
		ground_glow.light_energy = 1.2
	# 手电筒主体（圆柱形）
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 0.08
	body_mesh.bottom_radius = 0.09
	body_mesh.height = 0.5
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.15, 0.18)
	body_mat.metallic = 0.7
	body_mat.roughness = 0.4
	body_mesh.material = body_mat
	body.mesh = body_mesh
	body.rotation.x = deg_to_rad(90)
	add_child(body)
	_mesh_nodes.append(body)
	# 灯头（稍大的圆柱）
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.11
	head_mesh.bottom_radius = 0.11
	head_mesh.height = 0.12
	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.8, 0.8, 0.85)
	head_mat.metallic = 0.9
	head_mat.roughness = 0.2
	head_mesh.material = head_mat
	head.mesh = head_mesh
	head.rotation.x = deg_to_rad(90)
	head.position.z = -0.3
	add_child(head)
	_mesh_nodes.append(head)
	# 灯头玻璃（发光）
	var glass: MeshInstance3D = MeshInstance3D.new()
	var glass_mesh: CylinderMesh = CylinderMesh.new()
	glass_mesh.top_radius = 0.09
	glass_mesh.bottom_radius = 0.09
	glass_mesh.height = 0.03
	var glass_mat: StandardMaterial3D = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 1.0, 0.9)
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.98, 0.8)
	glass_mat.emission_energy_multiplier = 3.0
	glass_mesh.material = glass_mat
	glass.mesh = glass_mesh
	glass.rotation.x = deg_to_rad(90)
	glass.position.z = -0.38
	add_child(glass)
	_mesh_nodes.append(glass)
	# 开关按钮
	var btn: MeshInstance3D = MeshInstance3D.new()
	var btn_mesh: BoxMesh = BoxMesh.new()
	btn_mesh.size = Vector3(0.04, 0.02, 0.08)
	var btn_mat: StandardMaterial3D = StandardMaterial3D.new()
	btn_mat.albedo_color = Color(0.9, 0.2, 0.2)
	btn_mesh.material = btn_mat
	btn.mesh = btn_mesh
	btn.position = Vector3(0, 0.1, 0.05)
	add_child(btn)
	_mesh_nodes.append(btn)
	# 碰撞
	var col: CollisionShape3D = CollisionShape3D.new()
	var col_shape: BoxShape3D = BoxShape3D.new()
	col_shape.size = Vector3(0.3, 0.3, 0.7)
	col.shape = col_shape
	col.position.y = 0.15
	add_child(col)
