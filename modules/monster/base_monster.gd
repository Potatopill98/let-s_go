extends CharacterBody3D
class_name BaseMonster

# 怪物基础参数
@export var move_speed: float = 3.5
@export var chase_speed: float = 4.5
@export var detect_range: float = 25.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.2
@export var max_health: float = 30.0
@export var knockback_resistance: float = 0.3
@export var hit_stun_duration: float = 0.25

# 内部状态
var current_health: float = 30.0
var attack_timer: float = 0.0
var target_player: Player = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead: bool = false
var hit_stun_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	attack_timer = attack_cooldown
	add_to_group("monster")

# 只算水平距离
func get_horizontal_distance(pos_a: Vector3, pos_b: Vector3) -> float:
	var dx: float = pos_a.x - pos_b.x
	var dz: float = pos_a.z - pos_b.z
	return sqrt(dx*dx + dz*dz)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# 受击硬直倒计时
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	# 攻击CD递减
	if attack_timer > 0.0:
		attack_timer -= delta
	# 受击硬直期间不执行AI，保留击退速度
	if hit_stun_timer > 0.0:
		move_and_slide()
		return
	# 寻找最近玩家
	target_player = find_nearest_player()
	if target_player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var distance: float = get_horizontal_distance(global_position, target_player.global_position)
	if distance <= attack_range:
		# 攻击范围内停下攻击
		velocity.x = 0.0
		velocity.z = 0.0
		face_target(target_player.global_position)
		if attack_timer <= 0.0:
			perform_attack()
	else:
		# 追击玩家
		var move_dir: Vector3 = target_player.global_position - global_position
		move_dir.y = 0.0
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * chase_speed
		velocity.z = move_dir.z * chase_speed
		face_target(target_player.global_position)
	move_and_slide()

func find_nearest_player() -> Player:
	var players: Array = get_tree().get_nodes_in_group("player")
	var nearest: Player = null
	var min_dist: float = detect_range
	for node in players:
		var p: Player = node as Player
		if p == null or p.current_health <= 0.0:
			continue
		var dist: float = get_horizontal_distance(global_position, p.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = p
	return nearest

func face_target(target_pos: Vector3) -> void:
	var dir: Vector3 = target_pos - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	rotation.y = atan2(-dir.x, -dir.z)

func perform_attack() -> void:
	attack_timer = attack_cooldown
	if target_player == null or not is_instance_valid(target_player):
		return
	var knockback_dir: Vector3 = target_player.global_position - global_position
	knockback_dir.y = 0.0
	knockback_dir = knockback_dir.normalized()
	var knockback: Vector3 = knockback_dir * 3.0
	target_player.take_damage(attack_damage, knockback)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	# 应用击退并进入受击硬直，保证击退不被AI覆盖
	velocity += knockback * (1.0 - knockback_resistance)
	hit_stun_timer = hit_stun_duration
	if current_health <= 0.0:
		die()

func die() -> void:
	is_dead = true
	mesh_instance.scale = Vector3(1.2, 0.1, 1.2)
	var remove_timer: Timer = Timer.new()
	remove_timer.wait_time = 2.0
	remove_timer.one_shot = true
	remove_timer.timeout.connect(queue_free)
	add_child(remove_timer)
	remove_timer.start()
