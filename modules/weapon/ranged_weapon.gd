extends Node3D
class_name RangedWeapon

# Weapon properties
@export var weapon_name: String = "Pistol"
@export var damage: float = 25.0
@export var attack_cooldown: float = 0.3
@export var knockback_force: float = 5.0
@export var fire_range: float = 50.0
@export var mag_size: int = 12
@export var reload_time: float = 1.5

var attack_timer: float = 0.0
var owner_player: Player = null
var current_ammo: int = 12
var is_reloading: bool = false
var reload_timer: float = 0.0
var recoil_time: float = 0.0
var recoil_duration: float = 0.1
var original_rotation: Vector3 = Vector3.ZERO
var original_position: Vector3 = Vector3.ZERO
var muzzle_node: Node3D = null
var muzzle_flash: MeshInstance3D = null
var muzzle_light: OmniLight3D = null
var muzzle_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("weapon")
	current_ammo = mag_size
	original_rotation = rotation
	original_position = position
	# Create dedicated muzzle node at gun barrel tip
	muzzle_node = Node3D.new()
	muzzle_node.name = "Muzzle"
	muzzle_node.position = Vector3(0, 0, -0.35)
	add_child(muzzle_node)
	# Muzzle flash mesh
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
	# Raycast from camera (crosshair center) - this guarantees accurate hit
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + -camera.global_transform.basis.z * fire_range
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	var result: Dictionary = space_state.intersect_ray(query)
	var hit_point: Vector3 = to
	if result.has("position"):
		hit_point = result.position
	# Tracer: from CAMERA position (eye) to hit point - standard FPS approach (Neon Arena, CS, COD)
	# This guarantees the tracer is EXACTLY aligned with crosshair, never offset
	# Muzzle flash is still at muzzle for visual illusion
	spawn_tracer(camera.global_position, hit_point)
	if result.has("collider"):
		var hit_node: Node = result.collider as Node
		if hit_node is BaseMonster:
			var monster: BaseMonster = hit_node as BaseMonster
			var knockback_dir: Vector3 = -camera.global_transform.basis.z
			knockback_dir.y = 0.0
			knockback_dir = knockback_dir.normalized()
			var knockback: Vector3 = knockback_dir * knockback_force
			monster.take_damage(damage, knockback)

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

# Spawn bullet tracer - standard FPS implementation
# Draws a bright line from muzzle to hit point that fades out quickly
func spawn_tracer(from: Vector3, to: Vector3) -> void:
	var tracer: MeshInstance3D = MeshInstance3D.new()
	var tracer_mesh: BoxMesh = BoxMesh.new()
	var dist: float = from.distance_to(to)
	tracer_mesh.size = Vector3(0.02, 0.02, dist)
	var tracer_mat: StandardMaterial3D = StandardMaterial3D.new()
	tracer_mat.albedo_color = Color(1.0, 0.95, 0.5, 0.9)
	tracer_mat.emission_enabled = true
	tracer_mat.emission = Color(1.0, 0.9, 0.3)
	tracer_mat.emission_energy_multiplier = 8.0
	tracer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tracer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer_mesh.material = tracer_mat
	tracer.mesh = tracer_mesh
	# Position at midpoint
	tracer.global_position = (from + to) * 0.5
	# Orient along the line from muzzle to hit point
	tracer.look_at(to, Vector3.UP)
	get_tree().current_scene.add_child(tracer)
	# Fade out and auto destroy
	var lifetime: float = 0.1
	var timer: Timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(func(): tracer.queue_free())
	tracer.add_child(timer)
	timer.start()
	# Fade animation using tween
	var tween: Tween = create_tween()
	tween.tween_property(tracer_mat, "albedo_color:a", 0.0, lifetime)
	tween.tween_property(tracer_mat, "emission_energy_multiplier", 0.0, lifetime)



