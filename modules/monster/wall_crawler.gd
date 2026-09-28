extends CharacterBody3D

# ============================================================
# Wall Crawler - 贴墙潜伏怪物
# 平时贴在墙上不动, 玩家靠近后扑下来追击
# 第三关地下迷宫专属怪物
# ============================================================

enum State { IDLE, CHASE, ATTACK }

var current_state: int = State.IDLE
var target: Node3D = null
var chase_speed: float = 4.0
var attack_damage: float = 12.0
var attack_range: float = 2.0
var attack_cooldown: float = 1.2
var attack_timer: float = 0.0
var detect_range: float = 3.5
var health: float = 60.0
var max_health: float = 60.0
var is_dead: bool = false

var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var nav_agent: NavigationAgent3D = null
var _model_built: bool = false

func _ready() -> void:
	add_to_group("monster")
	_setup_multiplayer_sync()
	_build_model()
	# 初始贴墙状态: 半透明, 不动
	if mesh_instance != null:
		mesh_instance.visible = false
	set_physics_process(true)

func _setup_multiplayer_sync() -> void:
	var sync: MultiplayerSynchronizer = get_node_or_null("MultiplayerSynchronizer")
	if sync != null:
		var config: MultiplayerSynchronizerReplicationConfig = MultiplayerSynchronizerReplicationConfig.new()
		config.add_property("position", MultiplayerSynchronizerReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		config.add_property("rotation", MultiplayerSynchronizerReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		config.add_property("current_health", MultiplayerSynchronizerReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		config.add_property("is_dead", MultiplayerSynchronizerReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		sync.replication_config = config

func _physics_process(delta: float) -> void:
	if not NetworkManager.is_host():
		return
	if is_dead:
		return
	if attack_timer > 0:
		attack_timer -= delta
	_find_target()
	match current_state:
		State.IDLE:
			_idle_update(delta)
		State.CHASE:
			_chase_update(delta)
		State.ATTACK:
			_attack_update(delta)

func _find_target() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	var closest: Node3D = null
	var closest_dist: float = detect_range
	for p in players:
		if p == null:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = p
	if closest != null:
		target = closest
		if current_state == State.IDLE:
			_detach_from_wall()
			current_state = State.CHASE

func _idle_update(delta: float) -> void:
	# 贴墙不动, 身体隐藏, 只有眼睛微弱发光
	pass

func _detach_from_wall() -> void:
	# 从墙上扑下来
	if mesh_instance != null:
		mesh_instance.visible = true
	# 创建导航代理
	if nav_agent == null:
		nav_agent = NavigationAgent3D.new()
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 1.0
		add_child(nav_agent)

func _chase_update(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.IDLE
		return
	var dist: float = global_position.distance_to(target.global_position)
	if dist <= attack_range:
		current_state = State.ATTACK
		return
	if dist > 20.0:
		# 玩家跑太远, 回到idle
		current_state = State.IDLE
		target = null
		return
	# 朝玩家移动
	if nav_agent != null:
		nav_agent.target_position = target.global_position
		var next_pos: Vector3 = nav_agent.get_next_path_position()
		var dir: Vector3 = (next_pos - global_position).normalized()
		dir.y = 0
		if dir.length() > 0.1:
			velocity = dir * chase_speed
		else:
			velocity = Vector3.ZERO
	else:
		var dir: Vector3 = (target.global_position - global_position).normalized()
		dir.y = 0
		velocity = dir * chase_speed
	velocity.y -= 20.0 * delta
	move_and_slide()

func _attack_update(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.IDLE
		return
	var dist: float = global_position.distance_to(target.global_position)
	if dist > attack_range + 0.5:
		current_state = State.CHASE
		return
	velocity = Vector3.ZERO
	velocity.y -= 20.0 * delta
	move_and_slide()
	# 面向玩家
	var look_dir: Vector3 = (target.global_position - global_position).normalized()
	look_dir.y = 0
	if look_dir.length() > 0.1:
		look_at(global_position + look_dir, Vector3.UP)
	# 攻击
	if attack_timer <= 0:
		attack_timer = attack_cooldown
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		_die()
	else:
		# 被打时从墙上惊醒
		if current_state == State.IDLE:
			_detach_from_wall()
			current_state = State.CHASE
		# 击退
		if knockback_dir.length() > 0.1:
			velocity = knockback_dir * 6.0
			move_and_slide()

func _die() -> void:
	is_dead = true
	queue_free()

func _build_model() -> void:
	if _model_built:
		return
	_model_built = true
	# 身体(扁长形, 适合贴墙)
	mesh_instance = MeshInstance3D.new()
	var body_mesh: CapsuleMesh = CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 1.2
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.1, 0.12)
	body_mat.emission_enabled = true
	body_mat.emission = Color(0.6, 0.05, 0.1)
	body_mat.emission_energy_multiplier = 0.8
	body_mesh.material = body_mat
	mesh_instance.mesh = body_mesh
	mesh_instance.position.y = 0.8
	add_child(mesh_instance)
	# 眼睛(发光)
	var eye: MeshInstance3D = MeshInstance3D.new()
	var eye_mesh: SphereMesh = SphereMesh.new()
	eye_mesh.radius = 0.08
	eye_mesh.height = 0.16
	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.2, 0.15)
	eye_mat.emission_energy_multiplier = 4.0
	eye_mesh.material = eye_mat
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 1.0, -0.35)
	add_child(eye)
	# 碰撞
	collision_shape = CollisionShape3D.new()
	var col_shape: CapsuleShape3D = CapsuleShape3D.new()
	col_shape.radius = 0.4
	col_shape.height = 1.4
	collision_shape.shape = col_shape
	collision_shape.position.y = 0.8
	add_child(collision_shape)
