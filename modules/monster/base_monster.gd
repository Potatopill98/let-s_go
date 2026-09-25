extends CharacterBody3D
class_name BaseMonster

# 怪物基础参数
@export var move_speed: float = 3.5
@export var chase_speed: float = 5.0
@export var detect_range: float = 30.0
@export var attack_range: float = 2.2
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.2
@export var max_health: float = 30.0
@export var knockback_resistance: float = 0.2
@export var hit_stun_duration: float = 0.4

# 内部状态
var current_health: float = 30.0
var attack_timer: float = 0.0
var target_player: Player = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead: bool = false
var hit_stun_timer: float = 0.0
var stuck_timer: float = 0.0 # 防卡住计时器
var last_position: Vector3 = Vector3.ZERO

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	attack_timer = attack_cooldown
	add_to_group("monster")
	last_position = global_position

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
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	# 攻击CD递减
	if attack_timer > 0.0:
		attack_timer -= delta
	# 受击硬直
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
		move_and_slide()
		return
	# 每帧重新查找最近玩家，不会因为引用失效卡住
	target_player = find_nearest_player()
	if target_player == null:
		# 找不到玩家时缓慢向前巡逻，不会永久站住
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var distance: float = get_horizontal_distance(global_position, target_player.global_position)
	# 防卡住检测：如果速度不为0但位置没变化，强制重置
	if velocity.length() > 0.5:
		var moved_dist: float = get_horizontal_distance(global_position, last_position)
		if moved_dist < 0.01:
			stuck_timer += delta
			if stuck_timer > 0.5:
				# 卡住超过0.5秒，随机跳一下并重新计算方向
				velocity.y = 3.0
				stuck_timer = 0.0
		else:
			stuck_timer = 0.0
	last_position = global_position
	# 状态判断：攻击范围内停下攻击，范围外追击
	if distance <= attack_range:
		# 攻击范围内
		velocity.x = 0.0
		velocity.z = 0.0
		face_target(target_player.global_position)
		if attack_timer <= 0.0:
			perform_attack()
	else:
		# 追击玩家，直接设置速度，不会被其他逻辑覆盖
		var move_dir: Vector3 = target_player.global_position - global_position
		move_dir.y = 0.0
		if move_dir.length_squared() > 0.001:
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
	var knockback: Vector3 = knockback_dir * 4.0
	target_player.take_damage(attack_damage, knockback)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	# 直接设置击退速度，不叠加
	var knockback_force: float = knockback.length() * (1.0 - knockback_resistance)
	var knockback_dir: Vector3 = knockback.normalized()
	velocity.x = knockback_dir.x * knockback_force
	velocity.z = knockback_dir.z * knockback_force
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
