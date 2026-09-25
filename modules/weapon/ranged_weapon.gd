extends Node3D
class_name RangedWeapon

# 武器属性
@export var weapon_name: String = "手枪"
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
var muzzle_flash: MeshInstance3D = null

func _ready() -> void:
	add_to_group("weapon")
	current_ammo = mag_size
	original_rotation = rotation
	original_position = position
	# 创建枪口闪光
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh: BoxMesh = BoxMesh.new()
	flash_mesh.size = Vector3(0.15, 0.15, 0.15)
	var flash_mat: StandardMaterial3D = StandardMaterial3D.new()
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.8, 0.2, 1)
	flash_mat.emission_energy_multiplier = 5.0
	flash_mesh.material = flash_mat
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = Vector3(0, 0, -0.3)
	muzzle_flash.visible = false
	add_child(muzzle_flash)

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	# 射击后坐力动画
	if recoil_time > 0:
		recoil_time -= delta
		var t: float = recoil_time / recoil_duration
		position.z = original_position.z + (1 - t) * 0.1
		rotation.x = original_rotation.x + (1 - t) * 0.2
		if recoil_time <= 0:
			position = original_position
			rotation = original_rotation
			muzzle_flash.visible = false
	# 换弹动画
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
	muzzle_flash.visible = true
	if owner_player == null:
		return
	var camera: Camera3D = owner_player.get_node("Head/Camera3D") as Camera3D
	if camera == null:
		return
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + camera.global_transform.basis.z * -fire_range
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	var result: Dictionary = space_state.intersect_ray(query)
	if result.has("collider"):
		var hit_node: Node = result.collider as Node
		if hit_node is BaseMonster:
			var monster: BaseMonster = hit_node as BaseMonster
			var knockback_dir: Vector3 = camera.global_transform.basis.z * -1
			knockback_dir.y = 0.0
			knockback_dir = knockback_dir.normalized()
			var knockback: Vector3 = knockback_dir * knockback_force
			monster.take_damage(damage, knockback)

func reload() -> void:
	if is_reloading or current_ammo == mag_size:
		return
	is_reloading = true
	reload_timer = reload_time
	UIManager.show_message("换弹中...")


