extends Area3D

# ============================================================
# Flashlight Tool
# Lights up dark areas, cannot attack
# Pick it up to see in dark corridors
# ============================================================

var item_name: String = "手电筒"
var item_type: int = 0 # 0=tool, 1=weapon, 2=consumable
var can_attack: bool = false
var can_interact: bool = true
var interact_tag: String = "flashlight"
var is_held: bool = false
var holder: Node = null
var light: SpotLight3D = null

func _ready() -> void:
	add_to_group("holdable")
	_build_flashlight_model()
	light = SpotLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.8, 1)
	light.light_energy = 5.0
	light.spot_range = 15.0
	light.spot_angle = 45.0
	light.spot_attenuation = 1.0
	light.position = Vector3(0, 0, -0.2)
	light.rotation.x = deg_to_rad(-90)
	add_child(light)
	light.visible = false

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	visible = false
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	if light != null:
		light.visible = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	visible = true
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false
	if light != null:
		light.visible = false

func _build_flashlight_model() -> void:
	# Body
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 0.04
	body_mesh.bottom_radius = 0.045
	body_mesh.height = 0.25
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.15, 0.15)
	body_mat.metallic = 0.7
	body_mat.roughness = 0.4
	body_mesh.material = body_mat
	body.mesh = body_mesh
	body.rotation.x = deg_to_rad(90)
	add_child(body)
	# Lens
	var lens: MeshInstance3D = MeshInstance3D.new()
	var lens_mesh: CylinderMesh = CylinderMesh.new()
	lens_mesh.top_radius = 0.05
	lens_mesh.bottom_radius = 0.05
	lens_mesh.height = 0.03
	var lens_mat: StandardMaterial3D = StandardMaterial3D.new()
	lens_mat.albedo_color = Color(1.0, 0.95, 0.7, 1)
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(1.0, 0.9, 0.6, 1)
	lens_mat.emission_energy_multiplier = 3.0
	lens_mesh.material = lens_mat
	lens.mesh = lens_mesh
	lens.rotation.x = deg_to_rad(90)
	lens.position.z = -0.14
	add_child(lens)
