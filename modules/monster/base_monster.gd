extends CharacterBody3D
class_name BaseMonster

# ============================================================
# Base Monster - State machine with Sprite3D health bar
# Sprite3D has built-in billboard, no orientation issues
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

# Health bar - Sprite3D (built-in billboard, reliable)
var health_bar_bg: Sprite3D = null
var health_bar_fg: Sprite3D = null
# Shared white texture for all monsters (created once)
static var shared_white_texture: ImageTexture = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position
	_create_health_bar()

func _get_white_texture() -> ImageTexture:
	# Create shared 4x4 white texture once
	if shared_white_texture == null:
		var img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		shared_white_texture = ImageTexture.create_from_image(img)
	return shared_white_texture

func _create_health_bar() -> void:
	var tex: ImageTexture = _get_white_texture()
	# Background bar (dark)
	health_bar_bg = Sprite3D.new()
	health_bar_bg.texture = tex
	health_bar_bg.modulate = Color(0.1, 0.1, 0.1, 1)
	health_bar_bg.scale = Vector3(6.0, 0.8, 1)
	health_bar_bg.position = Vector3(0, 3.8, 0)
	health_bar_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_bg.no_depth_test = true
	add_child(health_bar_bg)
	# Foreground bar (health color) - same position, use region_rect to clip from right
	health_bar_fg = Sprite3D.new()
	health_bar_fg.texture = tex
	health_bar_fg.modulate = Color(0.2, 1.0, 0.3, 1)
	health_bar_fg.scale = Vector3(5.6, 0.55, 1)
	health_bar_fg.position = Vector3(0, 3.8, 0)
	health_bar_fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_fg.no_depth_test = true
	health_bar_fg.region_enabled = true
	health_bar_fg.region_rect = Rect2(0, 0, 4, 4)
	add_child(health_bar_fg)
	_update_health_bar_visual()

func _process(delta: float) -> void:
	# Stop processing when dead (prevents accessing freed nodes)
	if is_dead:
		return

func _update_health_bar_visual() -> void:
	if health_bar_fg == null or is_dead:
		return
	var ratio: float = clamp(current_health / max_health, 0.0, 1.0)
	# Use region_rect to clip from right (texture is 4x4)
	health_bar_fg.region_rect = Rect2(0, 0, 4.0 * ratio, 4)
	# Change color based on health
	if ratio <= 0.25:
		health_bar_fg.modulate = Color(1.0, 0.2, 0.2, 1)
	elif ratio <= 0.5:
		health_bar_fg.modulate = Color(1.0, 0.8, 0.2, 1)
	else:
		health_bar_fg.modulate = Color(0.2, 1.0, 0.3, 1)

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
	# Free health bars safely
	if health_bar_bg != null:
		health_bar_bg.queue_free()
		health_bar_bg = null
	if health_bar_fg != null:
		health_bar_fg.queue_free()
		health_bar_fg = null
	var t: Timer = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()
