extends CharacterBody3D
class_name BaseMonster

# ============================================================
# Base Monster - State machine with Label3D health bar
# Reference: GodotArenaFPS Enemy.gd - uses text characters for HP bar
# No textures, no meshes, no dynamic resources = zero crashes
# ============================================================

# Params
@export var move_speed: float = 6.0
@export var detect_range: float = 35.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.0
@export var max_health: float = 30.0
@export var hit_stun_time: float = 0.35
@export var knockback_reduce: float = 0.25
@export var use_fov_detection: bool = false  # 是否使用扇形视野检测（牢房怪物用）
@export var view_angle: float = 120.0  # 视野角度（度）
@export var view_range: float = 12.0  # 视野距离
@export var patrol_in_cell: bool = false  # 是否在牢房内巡逻待机
var is_alerted: bool = false  # 是否已警觉（检测到玩家后开始追击）
var alert_timer: float = 0.0  # 失去目标后保持警觉的时间
var home_position: Vector3 = Vector3.ZERO  # 初始位置（牢房位置）

# State
var current_health: float = 30.0
var attack_timer: float = 0.0
var hit_stun_timer: float = 0.0
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var stuck_check_timer: float = 0.0
var last_pos: Vector3 = Vector3.ZERO

# Health bar - Label3D (built-in billboard, rock solid)
var hp_label: Label3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D
var nav_agent: NavigationAgent3D = null

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position
	home_position = global_position
	_build_hp_bar()
	nav_agent = get_node_or_null("NavigationAgent3D") as NavigationAgent3D

## 头顶血条（Label3D billboard，参考霓虹竞技场实现）
func _build_hp_bar() -> void:
	hp_label = Label3D.new()
	hp_label.text = ""
	hp_label.font_size = 36
	hp_label.outline_size = 8
	hp_label.outline_modulate = Color(0, 0, 0, 0.9)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.no_depth_test = true
	hp_label.position = Vector3(0, 2.8, 0)
	hp_label.visible = false  # 初始隐藏，警觉后才显示
	add_child(hp_label)
	_update_hp_bar()

func _update_hp_bar() -> void:
	if hp_label == null or not is_instance_valid(hp_label):
		return
	var ratio: float = clamp(current_health / max_health, 0.0, 1.0)
	var bar_len: int = 12
	var filled: int = int(ratio * bar_len)
	var bar: String = "█".repeat(filled) + "░".repeat(bar_len - filled)
	var col: Color = Color(1.0, 0.2, 0.15)  # 满血红色
	if ratio < 0.3:
		col = Color(0.7, 0.1, 0.1)  # 低血量暗红
	elif ratio < 0.6:
		col = Color(1.0, 0.4, 0.1)  # 中血量橙红
	hp_label.modulate = col
	hp_label.text = "%s  %d" % [bar, int(current_health)]

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
	# 血条显示控制：只有警觉时才显示
	if hp_label != null and is_instance_valid(hp_label):
		if is_alerted and not is_dead:
			hp_label.visible = true
		else:
			hp_label.visible = false
	# 警觉计时器
	if is_alerted and alert_timer > 0.0:
		alert_timer -= delta
		if alert_timer <= 0.0:
			is_alerted = false

	var target: Player = null
	if use_fov_detection and not is_alerted:
		# 扇形视野检测模式：未警觉时只检测视野内的玩家
		target = find_player_in_fov()
		if target != null:
			is_alerted = true
			alert_timer = 8.0  # 检测到后保持8秒警觉
	else:
		# 普通模式或已警觉：用原来的范围检测
		target = find_nearest_player()
		if target == null and is_alerted:
			# 失去目标但保持警觉，回牢房方向
			var to_home: Vector3 = home_position - global_position
			to_home.y = 0.0
			if to_home.length() > 1.0:
				var dir_home: Vector3 = to_home.normalized()
				velocity.x = dir_home.x * move_speed * 0.5
				velocity.z = dir_home.z * move_speed * 0.5
				rotation.y = atan2(-dir_home.x, -dir_home.z)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			move_and_slide()
			return
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
	# Attack: horizontal + vertical range check
	if dist <= attack_range and vertical_dist <= 1.8:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_instance_valid(target):
				target.take_damage(attack_damage, to_target.normalized() * 3.0)
	else:
		var use_nav: bool = false
		# 使用NavigationAgent3D寻路
		if nav_agent != null and is_instance_valid(nav_agent):
			nav_agent.target_position = target.global_position
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			var to_next: Vector3 = next_pos - global_position
			to_next.y = 0.0
			# 如果寻路有效（下一个路径点距离当前位置>0.5米），用寻路
			if to_next.length() > 0.5:
				var dir: Vector3 = to_next.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				rotation.y = atan2(-dir.x, -dir.z)
				use_nav = true
		# Fallback：寻路失败或未就绪时，直接朝目标移动
		if not use_nav:
			var dir: Vector3 = to_target.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
	# Stuck detection - jump if stuck
	if velocity.length() > 1.0:
		stuck_check_timer += delta
		if global_position.distance_to(last_pos) < 0.05 and stuck_check_timer > 0.5:
			velocity.y = 4.0
			stuck_check_timer = 0.0
		if global_position.distance_to(last_pos) > 0.05:
			stuck_check_timer = 0.0
	last_pos = global_position
	move_and_slide()

func find_nearest_player() -> Player:
	var players: Array = get_tree().get_nodes_in_group("player")
	var nearest: Player = null
	var min_dist: float = detect_range
	for node in players:
		if not is_instance_valid(node):
			continue
		var p: Player = node as Player
		if p == null or p.current_health <= 0.0:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

## 360度圆形范围检测+墙壁遮挡：玩家在view_range米内且无墙壁遮挡则被发现
func find_player_in_fov() -> Player:
	var players: Array = get_tree().get_nodes_in_group("player")
	for node in players:
		if not is_instance_valid(node):
			continue
		var p: Player = node as Player
		if p == null or p.current_health <= 0.0:
			continue
		var to_player: Vector3 = p.global_position - global_position
		to_player.y = 0.0
		var dist: float = to_player.length()
		if dist > view_range or dist < 0.1:
			continue
		# 射线检测：有墙壁遮挡则看不到玩家
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var from: Vector3 = global_position + Vector3(0, 1.0, 0)
		var to: Vector3 = p.global_position + Vector3(0, 1.0, 0)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var result: Dictionary = space_state.intersect_ray(query)
		if result.is_empty() or (result.has("collider") and result["collider"] == p):
			return p
	return null

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	is_alerted = true  # 被攻击时触发警觉
	alert_timer = 10.0
	current_health -= amount
	_update_hp_bar()
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
	# Safely remove HP label
	if hp_label != null and is_instance_valid(hp_label):
		hp_label.queue_free()
		hp_label = null
	# Remove from group so players don't target freed corpses
	remove_from_group("monster")
	var t: Timer = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()
