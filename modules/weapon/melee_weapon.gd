extends Node3D
class_name MeleeWeapon

# 武器属性
@export var weapon_name: String = "木棒"
@export var damage: float = 15.0
@export var attack_cooldown: float = 0.8
@export var knockback_force: float = 8.0
@export var attack_range: float = 2.5
@export var attack_angle: float = 120.0

var attack_timer: float = 0.0
var owner_player: Player = null
var is_attacking: bool = false
var attack_anim_time: float = 0.0
var attack_anim_duration: float = 0.3
var original_rotation: Vector3 = Vector3.ZERO
var original_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("weapon")
	original_rotation = rotation
	original_position = position

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	# 挥砍动画
	if is_attacking:
		attack_anim_time += delta
		var t: float = attack_anim_time / attack_anim_duration
		if t >= 1.0:
			is_attacking = false
			rotation = original_rotation
			position = original_position
		else:
			# 挥砍轨迹：从右上挥到左下
			var swing_angle: float = sin(t * PI) * 1.5
			rotation.z = original_rotation.z - swing_angle
			rotation.x = original_rotation.x + sin(t * PI) * 0.5
			position.y = original_position.y - sin(t * PI) * 0.1
			position.z = original_position.z + sin(t * PI) * 0.2

func set_owner_player(player: Player) -> void:
	owner_player = player

func can_attack() -> bool:
	return attack_timer <= 0.0 and owner_player != null

func attack() -> void:
	if not can_attack():
		return
	attack_timer = attack_cooldown
	is_attacking = true
	attack_anim_time = 0.0
	if owner_player == null:
		return
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	var face_dir: Vector3 = -owner_player.global_transform.basis.z
	face_dir.y = 0.0
	face_dir = face_dir.normalized()
	for node in monsters:
		var m: BaseMonster = node as BaseMonster
		if m == null or m.is_dead:
			continue
		var to_monster: Vector3 = m.global_position - owner_player.global_position
		to_monster.y = 0.0
		var dist: float = to_monster.length()
		if dist > attack_range:
			continue
		var angle_cos: float = cos(deg_to_rad(attack_angle / 2.0))
		if to_monster.normalized().dot(face_dir) < angle_cos:
			continue
		var knockback_dir: Vector3 = to_monster.normalized()
		var knockback: Vector3 = knockback_dir * knockback_force
		m.take_damage(damage, knockback)

