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

func _ready() -> void:
	add_to_group("holdable")
	_build_wrench_model()

func pick_up(player: Node) -> void:
	is_held = true
	holder = player
	visible = false
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

func drop(drop_position: Vector3) -> void:
	is_held = false
	holder = null
	global_position = drop_position
	visible = true
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func _build_wrench_model() -> void:
	# 发光提示
	var glow: OmniLight3D = OmniLight3D.new()
	glow.light_color = Color(0.3, 0.6, 1.0)
	glow.light_energy = 1.5
	glow.omni_range = 4.0
	add_child(glow)
	# Handle
	var handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: CylinderMesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.035
	handle_mesh.height = 0.4
	var handle_mat: StandardMaterial3D = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.2, 0.5, 0.9)
	handle_mat.roughness = 0.4
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
