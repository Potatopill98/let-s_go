extends Area3D

# ============================================================
# Flashlight Tool
# 手持时提供照明，地上时也发光方便找到
# 只能拿一个东西，需要和队友配合
# ============================================================

var item_name: String = "手电筒"
var item_type: int = 0
var can_attack: bool = false
var can_interact: bool = false
var interact_tag: String = ""
var is_held: bool = false
var holder: Node = null

var player_in_range: bool = false
var flash_light: OmniLight3D = null
var light_spot: SpotLight3D = null

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
	if flash_light == null:
		flash_light = OmniLight3D.new()
		flash_light.light_color = Color(0.9, 0.95, 1.0)
		flash_light.omni_range = 6.0
		flash_light.position.y = 0.3
		add_child(flash_light)
	if light_spot == null:
		light_spot = SpotLight3D.new()
		light_spot.light_color = Color(1.0, 0.98, 0.9)
		light_spot.spot_range = 15.0
		light_spot.spot_angle = 35.0
		light_spot.spot_attenuation = 1.2
		light_spot.rotation.x = deg_to_rad(-90)
		light_spot.position = Vector3(0, 0.2, -0.2)
		add_child(light_spot)

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	visible = false
	_ensure_lights()
	flash_light.light_energy = 1.5
	light_spot.light_energy = 2.5
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	visible = true
	_ensure_lights()
	flash_light.light_energy = 2.0
	light_spot.light_energy = 0.5
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func _build_flashlight_model() -> void:
	_ensure_lights()
	flash_light.light_energy = 2.0
	light_spot.light_energy = 0.5
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 0.05
	body_mesh.bottom_radius = 0.06
	body_mesh.height = 0.3
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.15, 0.18)
	body_mat.metallic = 0.7
	body_mat.roughness = 0.4
	body_mesh.material = body_mat
	body.mesh = body_mesh
	body.rotation.x = deg_to_rad(90)
	add_child(body)
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.07
	head_mesh.bottom_radius = 0.07
	head_mesh.height = 0.08
	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.8, 0.8, 0.85)
	head_mat.metallic = 0.9
	head_mat.roughness = 0.2
	head_mesh.material = head_mat
	head.mesh = head_mesh
	head.rotation.x = deg_to_rad(90)
	head.position.z = -0.18
	add_child(head)
	var glass: MeshInstance3D = MeshInstance3D.new()
	var glass_mesh: CylinderMesh = CylinderMesh.new()
	glass_mesh.top_radius = 0.06
	glass_mesh.bottom_radius = 0.06
	glass_mesh.height = 0.02
	var glass_mat: StandardMaterial3D = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 1.0, 0.9)
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.98, 0.8)
	glass_mat.emission_energy_multiplier = 3.0
	glass_mesh.material = glass_mat
	glass.mesh = glass_mesh
	glass.rotation.x = deg_to_rad(90)
	glass.position.z = -0.23
	add_child(glass)
	var col: CollisionShape3D = CollisionShape3D.new()
	var col_shape: BoxShape3D = BoxShape3D.new()
	col_shape.size = Vector3(0.2, 0.2, 0.5)
	col.shape = col_shape
	col.position.y = 0.1
	add_child(col)