extends CharacterBody3D
class_name Player

# Movement params
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
# Dodge params
@export var dodge_speed: float = 12.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.0
# Punch params
@export var punch_damage: float = 5.0
@export var punch_cooldown: float = 1.0
# Health params
@export var max_health: float = 100.0
var current_health: float = 100.0
@export var hit_stun_duration: float = 0.2

# Internal state
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_move_speed: float = 5.0
var dodge_timer: float = 0.0
var dodge_cd_timer: float = 0.0
var is_dodging: bool = false
var punch_cd_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var hit_stun_timer: float = 0.0
# Weapon system
var weapons: Array = []
var current_weapon_index: int = -1

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head.position.y = 1.6
	current_move_speed = walk_speed
	add_to_group("player")

func _input(event: InputEvent) -> void:
	# Mouse look - highest priority, always works even when repairing
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.0 + 0.01, PI / 2.0 - 0.01)

func _unhandled_input(event: InputEvent) -> void:
	# Skip input during hit stun
	if hit_stun_timer > 0.0:
		return
	# ESC toggle mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Dodge
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q and dodge_cd_timer <= 0.0 and not is_dodging and is_on_floor():
		start_dodge()
	# Weapon switch 1/2
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		switch_weapon(0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		switch_weapon(1)
	# Reload R
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reload_current_weapon()

func _physics_process(delta: float) -> void:
	# Timers
	if dodge_cd_timer > 0.0:
		dodge_cd_timer -= delta
	if punch_cd_timer > 0.0:
		punch_cd_timer -= delta
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
	# Update UI health
	UIManager.update_health(current_health, max_health)
	# Attack check
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dodging and hit_stun_timer <= 0.0:
		if current_weapon_index >= 0 and current_weapon_index < weapons.size():
			var weapon: Node = weapons[current_weapon_index]
			if weapon != null and weapon.can_attack():
				weapon.attack()
		elif punch_cd_timer <= 0.0:
			start_punch()
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
		if dodge_timer <= 0.0:
			is_dodging = false
	else:
		if hit_stun_timer <= 0.0:
			velocity.x = move_dir.x * current_move_speed
			velocity.z = move_dir.z * current_move_speed
		# Jump
		if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
			velocity.y = jump_velocity
		# Run
		if Input.is_key_pressed(KEY_SHIFT):
			current_move_speed = run_speed
		else:
			current_move_speed = walk_speed
	move_and_slide()

func start_dodge() -> void:
	is_dodging = true
	dodge_timer = dodge_duration
	dodge_cd_timer = dodge_cooldown
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length_squared() < 0.1:
		dodge_direction = -transform.basis.z
	else:
		dodge_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	dodge_direction.y = 0.0

func start_punch() -> void:
	punch_cd_timer = punch_cooldown
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	var hit_monster: Node = null
	var min_dist: float = 3.0
	var face_dir: Vector3 = -global_transform.basis.z
	face_dir.y = 0.0
	face_dir = face_dir.normalized()
	for node in monsters:
		var m: Node = node
		if m == null or m.is_dead:
			continue
		var to_monster: Vector3 = m.global_position - global_position
		to_monster.y = 0.0
		var dist: float = to_monster.length()
		if dist >= min_dist:
			continue
		var dot: float = to_monster.normalized().dot(face_dir)
		if dot < 0.5:
			continue
		min_dist = dist
		hit_monster = m
	if hit_monster != null:
		var knockback_dir: Vector3 = hit_monster.global_position - global_position
		knockback_dir.y = 0.0
		if knockback_dir.length_squared() > 0.001:
			knockback_dir = knockback_dir.normalized()
		var knockback: Vector3 = knockback_dir * 10.0
		hit_monster.take_damage(punch_damage, knockback)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0.0:
		return
	current_health -= amount
	velocity += knockback
	hit_stun_timer = hit_stun_duration
	if current_health <= 0.0:
		current_health = 0.0

func equip_weapon(weapon: Node) -> void:
	if weapon == null:
		return
	if current_weapon_index >= 0 and current_weapon_index < weapons.size():
		var old_weapon: Node = weapons[current_weapon_index]
		if old_weapon != null:
			old_weapon.visible = false
	weapons.append(weapon)
	if weapon.has_method("set_owner_player"):
		weapon.set_owner_player(self)
	var mount: Node3D = get_node("Head/WeaponMount") as Node3D
	if mount != null:
		mount.add_child(weapon)
		weapon.position = Vector3(0.3, -0.2, -0.5)
	current_weapon_index = weapons.size() - 1
	for w in weapons:
		w.visible = false
	weapon.visible = true

func switch_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if index == current_weapon_index:
		return
	if current_weapon_index >= 0 and current_weapon_index < weapons.size():
		var old_weapon: Node = weapons[current_weapon_index]
		if old_weapon != null:
			old_weapon.visible = false
	current_weapon_index = index
	var new_weapon: Node = weapons[current_weapon_index]
	if new_weapon != null:
		new_weapon.visible = true

func reload_current_weapon() -> void:
	if current_weapon_index < 0 or current_weapon_index >= weapons.size():
		return
	var weapon: Node = weapons[current_weapon_index]
	if weapon != null and weapon.has_method("reload"):
		weapon.reload()

