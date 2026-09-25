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

func _ready() -> void:
	add_to_group("weapon")
	current_ammo = mag_size

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			is_reloading = false
			current_ammo = mag_size

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
