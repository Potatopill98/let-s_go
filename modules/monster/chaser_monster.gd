extends BaseMonster

## 追逐型怪物（第二关Boss）
## 体型巨大塞满通道，可穿过障碍物，速度慢但一直追

@export var chase_speed: float = 2.5  # 玩家速度的一半

func _ready() -> void:
	super._ready()
	move_speed = chase_speed
	attack_damage = 999.0
	max_health = 500.0
	current_health = 500.0
	attack_range = 3.0
	attack_cooldown = 1.0
	detect_range = 500.0
	use_fov_detection = false
	# 碰撞层：只和玩家碰撞，不和障碍物碰撞（可以穿过障碍）
	collision_layer = 2
	collision_mask = 1  # 只检测玩家层
	# 血条
	if hp_label != null and is_instance_valid(hp_label):
		hp_label.visible = false  # Boss不显示血条

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	if attack_timer > 0.0:
		attack_timer -= delta
	# 永远保持警觉
	is_alerted = true
	alert_timer = 10.0
	var target: Player = find_nearest_player()
	if target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var to_target: Vector3 = target.global_position - global_position
	var vertical_dist: float = abs(to_target.y)
	to_target.y = 0.0
	var dist: float = to_target.length()
	if dist > 0.1:
		rotation.y = atan2(-to_target.x, -to_target.z)
	# 攻击：碰到直接秒杀
	if dist <= attack_range and vertical_dist <= 4.0:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_instance_valid(target):
				target.current_health = 0.0
				target.take_damage(999.0, to_target.normalized() * 5.0)
	else:
		# 直接朝玩家移动，不寻路（穿过障碍物）
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	move_and_slide()