extends BaseMonster

## 追逐型怪物（第二关Boss）
## 体型巨大塞满通道，可穿过所有障碍物，速度慢但一直追

@export var chase_speed: float = 2.5

func _ready() -> void:
	super._ready()
	move_speed = chase_speed
	attack_damage = 999.0
	max_health = 500.0
	current_health = 500.0
	attack_range = 3.5
	attack_cooldown = 1.0
	detect_range = 500.0
	use_fov_detection = false
	# 不参与物理碰撞，可以穿过所有东西
	collision_layer = 0
	collision_mask = 0
	if hp_label != null and is_instance_valid(hp_label):
		hp_label.visible = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if attack_timer > 0.0:
		attack_timer -= delta
	is_alerted = true
	alert_timer = 10.0
	var target: Player = find_nearest_player()
	if target == null:
		return
	var to_target: Vector3 = target.global_position - global_position
	var vertical_dist: float = abs(to_target.y)
	to_target.y = 0.0
	var dist: float = to_target.length()
	if dist > 0.1:
		rotation.y = atan2(-to_target.x, -to_target.z)
	# 攻击：碰到直接秒杀
	if dist <= attack_range and vertical_dist <= 4.0:
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_instance_valid(target):
				target.current_health = 0.0
				target.take_damage(999.0, to_target.normalized() * 5.0)
	else:
		# 直接朝玩家移动，穿过所有障碍物
		var dir: Vector3 = to_target.normalized()
		global_position.x += dir.x * move_speed * delta
		global_position.z += dir.z * move_speed * delta
		# 保持在地面高度
		global_position.y = 2.0