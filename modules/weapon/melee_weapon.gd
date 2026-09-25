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

func _ready() -> void:
	add_to_group("weapon")

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

func set_owner_player(player: Player) -> void:
	owner_player = player

func can_attack() -> bool:
	return attack_timer <= 0.0 and owner_player != null

func attack() -> void:
	if not can_attack():
		return
	attack_timer = attack_cooldown
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
