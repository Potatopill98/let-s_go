extends Node3D
class_name RangedWeapon

# ============================================================
# Pistol - Fully referenced from Neon Arena implementation
# Structure: procedural weapon model + muzzle node + tracer from camera
# ============================================================

# Weapon properties
@export var weapon_name: String = "Pistol"
@export var damage: float = 25.0
@export var attack_cooldown: float = 0.3
@export var knockback_force: float = 5.0
@export var fire_range: float = 50.0
@export var mag_size: int = 12
@export var reload_time: float = 1.5

# Internal state
var attack_timer: float = 0.0
var owner_player: Player = null
var current_ammo: int = 12
var is_reloading: bool = false
var reload_timer: float = 0.0
var recoil_time: float = 0.0
var recoil_duration: float = 0.1
var original_rotation: Vector3 = Vector3.ZERO
var original_position: Vector3 = Vector3.ZERO

# Muzzle system (reference: Neon Arena _muzzle_node)
var muzzle_node: Node3D = null
var muzzle_flash: MeshInstance3D = null
var muzzle_light: OmniLight3D = null
var muzzle_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("weapon")
	current_ammo = mag_size
	original_rotation = rotation
	original_position = position
	_build_pistol_model()
	_setup_muzzle()

# ============================================================
# Build pistol model - referenced from Neon Arena _build_pistol
# ============================================================
func _build_pistol_model() -> void:
	var d: float = 1.0
	# Materials
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.35, 0.25, 0.55)
	body_mat.roughness = 0.45
	body_mat.metallic = 0.55
	var dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.1, 0.11, 0.14)
	dark_mat.roughness = 0.35
	dark_mat.metallic = 0.65
	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.65, 0.67, 0.72)
	metal_mat.roughness = 0.2
	metal_mat.metallic = 0.9
	var accent_mat: StandardMaterial3D = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.5, 0.8, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.5, 0.8, 1.0)
	accent_mat.emission_energy_multiplier = 2.5

	# Slide
	var slide: MeshInstance3D = _make_box(Vector3(0.07 * d, 0.08 * d, 0.28 * d), body_mat)
	slide.position = Vector3(0, 0.015 * d, -0.09)
	add_child(slide)
	# Slide front bevel
	var slide_front: MeshInstance3D = _make_box(Vector3(0.065 * d, 0.06 * d, 0.06 * d), body_mat)
	slide_front.position = Vector3(0, 0.01 * d, -0.22)
	slide_front.rotation_degrees.x = -8
	add_child(slide_front)
	# Rear grooves (3 anti-slip grooves)
	for i in range(3):
		var groove: MeshInstance3D = _make_box(Vector3(0.072 * d, 0.012 * d, 0.01), dark_mat)
		groove.position = Vector3(0, 0.015 * d, 0.01 + i * 0.015)
		add_child(groove)
	# Front sight
	var front_sight: MeshInstance3D = _make_box(Vector3(0.018, 0.03, 0.01), accent_mat)
	front_sight.position = Vector3(0, 0.06 * d, -0.21)
	add_child(front_sight)
	# Rear sight
	var rear_sight: MeshInstance3D = _make_box(Vector3(0.045, 0.025, 0.012), dark_mat)
	rear_sight.position = Vector3(0, 0.055 * d, 0.03)
	add_child(rear_sight)
	# Barrel
	var barrel: MeshInstance3D = _make_cylinder(0.02 * d, 0.06 * d, dark_mat)
	barrel.position = Vector3(0, -0.005 * d, -0.25)
	barrel.rotation.x = deg_to_rad(90)
	add_child(barrel)
	# Muzzle ring
	var muzzle_ring: MeshInstance3D = _make_cylinder(0.025 * d, 0.025, metal_mat)
	muzzle_ring.position = Vector3(0, -0.005 * d, -0.29)
	muzzle_ring.rotation.x = deg_to_rad(90)
	add_child(muzzle_ring)
	# Grip
	var grip: MeshInstance3D = _make_box(Vector3(0.055 * d, 0.15 * d, 0.07 * d), dark_mat)
	grip.position = Vector3(0, -0.08 * d, 0.02)
	grip.rotation_degrees.x = 15
	add_child(grip)
	# Trigger guard
	var trigger_guard: MeshInstance3D = _make_box(Vector3(0.05 * d, 0.04 * d, 0.05 * d), dark_mat)
	trigger_guard.position = Vector3(0, -0.04 * d, -0.05)
	add_child(trigger_guard)
	# Trigger
	var trigger: MeshInstance3D = _make_box(Vector3(0.015 * d, 0.03 * d, 0.01 * d), metal_mat)
	trigger.position = Vector3(0, -0.035 * d, -0.05)
	add_child(trigger)

# ============================================================
# Setup muzzle node - referenced from Neon Arena _muzzle_node
# ============================================================
func _setup_muzzle() -> void:
	muzzle_node = Node3D.new()
	muzzle_node.name = "Muzzle"
	muzzle_node.position = Vector3(0.0, 0.0, -0.32)
	add_child(muzzle_node)
	# Muzzle flash mesh (sphere - reference Neon Arena)
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.06
	flash_mesh.height = 0.12
	var flash_mat: StandardMaterial3D = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.75, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.7, 0.3)
	flash_mat.emission_energy_multiplier = 6.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mesh.material = flash_mat
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.visible = false
	muzzle_node.add_child(muzzle_flash)
	# Muzzle point light
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.85, 0.45)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 8.0
	muzzle_node.add_child(muzzle_light)

func _make_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	bm.surface_set_material(0, mat)
	mi.mesh = bm
	return mi

func _make_cylinder(radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.surface_set_material(0, mat)
	mi.mesh = cm
	return mi

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	# Recoil animation
	if recoil_time > 0:
		recoil_time -= delta
		var t: float = recoil_time / recoil_duration
		position.z = original_position.z + (1 - t) * 0.1
		rotation.x = original_rotation.x + (1 - t) * 0.2
		if recoil_time <= 0:
			position = original_position
			rotation = original_rotation
	# Muzzle flash timer
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		muzzle_light.light_energy = 6.0 * (muzzle_flash_timer / 0.06)
		muzzle_flash.visible = muzzle_flash_timer > 0.0
		if muzzle_flash_timer <= 0.0:
			muzzle_light.light_energy = 0.0
			muzzle_flash.visible = false
	# Reload animation
	if is_reloading:
		reload_timer -= delta
		var reload_t: float = 1.0 - (reload_timer / reload_time)
		rotation.z = original_rotation.z + sin(reload_t * PI * 2) * 0.3
		position.y = original_position.y - sin(reload_t * PI) * 0.15
		if reload_timer <= 0.0:
			is_reloading = false
			current_ammo = mag_size
			rotation = original_rotation
			position = original_position

func set_owner_player(player: Player) -> void:
	owner_player = player

func can_attack() -> bool:
	return attack_timer <= 0.0 and owner_player != null and not is_reloading

func attack() -> void:
	if not can_attack():
		return
	if current_ammo <= 0:
		reload()
		return
	attack_timer = attack_cooldown
	current_ammo -= 1
	recoil_time = recoil_duration
	trigger_muzzle_flash()
	if owner_player == null:
		return
	var camera: Camera3D = owner_player.get_node("Head/Camera3D") as Camera3D
	if camera == null:
		return
	# ============================================================
	# Spawn actual bullet entity from muzzle position
	# Bullet flies independently after spawn, no longer tied to gun
	# Direction = camera forward (guarantees crosshair accuracy)
	# ============================================================
	var bullet_scene: PackedScene = load("res://modules/weapon/bullet.tscn")
	if bullet_scene == null:
		return
	var bullet: Node = bullet_scene.instantiate()
	if bullet == null:
		return
	var shoot_dir: Vector3 = -camera.global_transform.basis.z
	shoot_dir = shoot_dir.normalized()
	bullet.damage = damage
	get_tree().current_scene.add_child(bullet)
	bullet.setup(shoot_dir, muzzle_node.global_position)

func reload() -> void:
	if is_reloading or current_ammo == mag_size:
		return
	is_reloading = true
	reload_timer = reload_time
	UIManager.show_message("Reloading...")

func trigger_muzzle_flash() -> void:
	muzzle_flash_timer = 0.06
	muzzle_flash.visible = true
	muzzle_light.light_energy = 6.0
	muzzle_flash.rotation_degrees.z = randf_range(0, 360)
