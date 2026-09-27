extends BaseMonster

## 追逐型怪物（第二关Boss）
## 比玩家稍慢，但碰到直接秒杀，会自动寻路绕过障碍物

@export var chase_speed: float = 5.5  # 比玩家奔跑稍慢
@export var one_hit_kill: bool = true  # 碰到直接死

func _ready() -> void:
	super._ready()
	move_speed = chase_speed
	attack_damage = 999.0  # 秒杀
	max_health = 200.0
	current_health = 200.0
	attack_range = 2.5
	attack_cooldown = 0.8
	detect_range = 200.0  # 超远检测范围，一直在追
	use_fov_detection = false  # 不需要视野检测，直接追
	# 体型放大1.3倍
	scale = Vector3(1.3, 1.3, 1.3)
	# 血条调高一点
	if hp_label != null and is_instance_valid(hp_label):
		hp_label.position = Vector3(0, 3.5, 0)
		hp_label.font_size = 48

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
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
		move_and_slide()
		return
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
	if dist <= attack_range and vertical_dist <= 2.5:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_instance_valid(target):
				if one_hit_kill:
					target.current_health = 0.0
					target.take_damage(999.0, to_target.normalized() * 5.0)
				else:
					target.take_damage(attack_damage, to_target.normalized() * 3.0)
	else:
		# 寻路追击
		var use_nav: bool = false
		if nav_agent != null and is_instance_valid(nav_agent):
			nav_agent.target_position = target.global_position
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			var to_next: Vector3 = next_pos - global_position
			to_next.y = 0.0
			if to_next.length() > 0.5:
				var dir: Vector3 = to_next.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				rotation.y = atan2(-dir.x, -dir.z)
				use_nav = true
		if not use_nav:
			var dir: Vector3 = to_target.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
	# 卡住检测
	if velocity.length() > 1.0:
		stuck_check_timer += delta
		if global_position.distance_to(last_pos) < 0.05 and stuck_check_timer > 0.5:
			velocity.y = 5.0
			stuck_check_timer = 0.0
		if global_position.distance_to(last_pos) > 0.05:
			stuck_check_timer = 0.0
	last_pos = global_position
	move_and_slide()