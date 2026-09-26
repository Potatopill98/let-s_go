extends CharacterBody3D
class_name BaseMonster

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
var health_bar_3d: Sprite3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position
	# Create health bar (bigger, with border)
	health_bar_3d = Sprite3D.new()
	health_bar_3d.texture = make_health_bar_texture()
	health_bar_3d.scale = Vector3(0.08, 0.08, 1)
	health_bar_3d.position = Vector3(0, 2.5, 0)
	health_bar_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_3d.no_depth_test = true
	add_child(health_bar_3d)

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
	# 攻击判定：水平距离+垂直高度都要在范围内（垂直不超过怪物高度1.8米）
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
	update_health_bar()
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
	if health_bar_3d != null:
		health_bar_3d.queue_free()
	var t: Timer = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func make_health_bar_texture() -> ImageTexture:
	var width: int = 128
	var height: int = 16
	var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	# Black border background
	img.fill(Color(0, 0, 0, 1))
	# Health bar color: green >50%, yellow >25%, red <=25%
	var health_ratio: float = current_health / max_health
	var bar_color: Color = Color(0.2, 1.0, 0.2, 1)
	if health_ratio <= 0.25:
		bar_color = Color(1.0, 0.2, 0.2, 1)
	elif health_ratio <= 0.5:
		bar_color = Color(1.0, 0.8, 0.2, 1)
	# Draw health bar with 2px border
	var bar_width: int = int((width - 4) * health_ratio)
	for x in range(2, 2 + bar_width):
		for y in range(2, height - 2):
			img.set_pixel(x, y, bar_color)
	return ImageTexture.create_from_image(img)

func update_health_bar() -> void:
	if health_bar_3d != null:
		health_bar_3d.texture = make_health_bar_texture()


