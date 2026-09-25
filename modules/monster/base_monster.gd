extends CharacterBody3D
class_name BaseMonster

# ==================== 基础参数（参考常见游戏稳定数值） ====================
@export var move_speed: float = 4.0          # 追击速度
@export var detect_range: float = 35.0       # 检测玩家范围
@export var attack_range: float = 2.0        # 攻击距离
@export var attack_damage: float = 8.0       # 攻击伤害
@export var attack_cooldown: float = 1.0     # 攻击间隔
@export var max_health: float = 30.0         # 最大血量
@export var hit_stun_time: float = 0.35      # 受击硬直时间
@export var knockback_reduce: float = 0.25   # 击退抗性（0=全额击退，1=完全免疫）

# ==================== 内部状态 ====================
var current_health: float = 30.0
var attack_timer: float = 0.0
var hit_stun_timer: float = 0.0
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# 防卡住用
var stuck_check_timer: float = 0.0
var last_pos: Vector3 = Vector3.ZERO

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position

# ==================== 主逻辑：每帧重新计算，不缓存状态，最稳定 ====================
func _physics_process(delta: float) -> void:
	# 死亡处理
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	# 计时器
	if attack_timer > 0.0:
		attack_timer -= delta
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
		# 硬直期间只应用击退，不做AI，然后直接移动
		move_and_slide()
		return
	# 每帧重新找最近玩家，不会因为引用失效卡住
	var target: Player = find_nearest_player()
	if target == null:
		# 没目标就站住
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	# 计算水平距离
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()
	# 朝向玩家
	if dist > 0.1:
		rotation.y = atan2(-to_target.x, -to_target.z)
	# 状态判断：距离够近就攻击，否则追击
	if dist <= attack_range:
		# 攻击范围内：停下，CD好了就打
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			target.take_damage(attack_damage, to_target.normalized() * 3.0)
	else:
		# 追击：直接设置速度朝向玩家，最简单稳定
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	# 防卡住：如果速度不为0但0.5秒没移动，跳一下
	if velocity.length() > 1.0:
		stuck_check_timer += delta
		if global_position.distance_to(last_pos) < 0.05 and stuck_check_timer > 0.5:
			velocity.y = 4.0
			stuck_check_timer = 0.0
		if global_position.distance_to(last_pos) > 0.05:
			stuck_check_timer = 0.0
	last_pos = global_position
	# 移动
	move_and_slide()

# ==================== 工具方法 ====================
func find_nearest_player() -> Player:
	var players: Array = get_tree().get_nodes_in_group("player")
	var nearest: Player = null
	var min_dist: float = detect_range
	for node in players:
		var p: Player = node as Player
		if p == null or p.current_health <= 0.0:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

# ==================== 受击接口 ====================
func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	# 直接设置击退速度，不叠加，避免速度抵消
	var kb_force: float = knockback.length() * (1.0 - knockback_reduce)
	var kb_dir: Vector3 = knockback.normalized()
	velocity.x = kb_dir.x * kb_force
	velocity.z = kb_dir.z * kb_force
	hit_stun_timer = hit_stun_time
	if current_health <= 0.0:
		die()

func die() -> void:
	is_dead = true
	mesh.scale = Vector3(1.3, 0.1, 1.3)
	var t: Timer = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()
