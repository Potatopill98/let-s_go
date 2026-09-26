extends CharacterBody3D
class_name BaseMonster

# ============================================================
# Base Monster - State machine with mesh-based health bar
# No dynamic texture creation = no memory leak
# ============================================================

# Params
@export var move_speed: float = 3.0
@export var detect_range: float = 35.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.0
@export var max_health: float = 30.0
@export var hit_stun_time: float = 0.35
@export var knockback_reduce: float = 0.25

# State
var current_health: float = 30.0
var attack_timer: float = 0.0
var hit_stun_timer: float = 0.0
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var stuck_check_timer: float = 0.0
var last_pos: Vector3 = Vector3.ZERO

# Health bar (mesh-based, no dynamic textures)
var health_bar_container: Node3D = null
var health_bar_fg: MeshInstance3D = null
var health_bar_fg_mat: StandardMaterial3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position
	_create_health_bar()

func _create_health_bar() -> void:
	# Container high above head, 5x bigger for visibility
	health_bar_container = Node3D.new()
	health_bar_container.position = Vector3(0, 3.8, 0)
	add_child(health_bar_container)
	# Background (dark) - double sided, rotated to face camera
	var bg_mat: StandardMaterial3D = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.05, 0.05, 0.05, 1)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var health_bar_bg: MeshInstance3D = MeshInstance3D.new()
	var bg_mesh: PlaneMesh = PlaneMesh.new()
	bg_mesh.size = Vector2(6.0, 0.8)
	health_bar_bg.mesh = bg_mesh
	health_bar_bg.material_override = bg_mat
	health_bar_bg.rotation.y = PI
	health_bar_container.add_child(health_bar_bg)
	# Foreground (health fill) - pivot at left side, double sided
	health_bar_fg_mat = StandardMaterial3D.new()
	health_bar_fg_mat.albedo_color = Color(0.2, 1.0, 0.3, 1)
	health_bar_fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_bar_fg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	health_bar_fg = MeshInstance3D.new()
	var fg_mesh: PlaneMesh = PlaneMesh.new()
	fg_mesh.size = Vector2(5.6, 0.55)
	health_bar_fg.mesh = fg_mesh
	health_bar_fg.material_override = health_bar_fg_mat
	# Offset to left so scaling shrinks from right side
	health_bar_fg.position.x = -2.8
	health_bar_fg.rotation.y = PI
	health_bar_container.add_child(health_bar_fg)
	_update_health_bar_visual()

func _process(delta: float) -> void:
	# Make health bar always face the camera
	if health_bar_container != null:
		var camera: Camera3D = get_viewport().get_camera_3d()
		if camera != null:
			health_bar_container.look_at(camera.global_position, Vector3.UP)

func _update_health_bar_visual() -> void:
	if health_bar_fg == null or health_bar_fg_mat == null:
		return
	var ratio: float = clamp(current_health / max_health, 0.0, 1.0)
	# Scale foreground from left pivot
	health_bar_fg.scale.x = ratio
	# Change color based on health
	if ratio <= 0.25:
		health_bar_fg_mat.albedo_color = Color(1.0, 0.2, 0.2, 1)
	elif ratio <= 0.5:
		health_bar_fg_mat.albedo_color = Color(1.0, 0.8, 0.2, 1)
	else:
		health_bar_fg_mat.albedo_color = Color(0.2, 1.0, 0.3, 1)

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
	# Attack: horizontal + vertical range check
	if dist <= attack_range and vertical_dist <= 1.8:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			target.take_damage(attack_damage, to_target.normalized() * 3.0)
	else:
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
		var p: Player = node as Player
		if p == null or p.current_health <= 0.0:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	_update_health_bar_visual()
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
	if health_bar_container != null:
		health_bar_container.queue_free()
	var t: Timer = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()
