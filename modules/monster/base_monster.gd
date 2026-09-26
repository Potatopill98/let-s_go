extends CharacterBody3D
class_name BaseMonster

# ============================================================
# Base Monster - State machine with Label3D health bar
# Reference: GodotArenaFPS Enemy.gd - uses text characters for HP bar
# No textures, no meshes, no dynamic resources = zero crashes
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

# Health bar - Label3D (built-in billboard, rock solid)
var hp_label: Label3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	current_health = max_health
	add_to_group("monster")
	last_pos = global_position
	_build_hp_bar()

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
	add_child(hp_label)
	_update_hp_bar()

func _update_hp_bar() -> void:
	if hp_label == null or not is_instance_valid(hp_label):
		return
	var ratio: float = clamp(current_health / max_health, 0.0, 1.0)
	var bar_len: int = 12
	var filled: int = int(ratio * bar_len)
	var bar: String = "█".repeat(filled) + "░".repeat(bar_len - filled)
	var col: Color = Color(0.2, 1.0, 0.4)
	if ratio < 0.3:
		col = Color(1.0, 0.2, 0.15)
	elif ratio < 0.6:
		col = Color(1.0, 0.8, 0.2)
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
			if is_instance_valid(target):
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

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
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
