extends CharacterBody3D
class_name Player

# ============================================================
# Player Controller with Holdable Item System
# One hand, one item at a time
# Empty hand: can punch
# Tool: can interact, cannot attack
# Weapon: can attack, cannot repair
# ============================================================

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

# Holdable item system - one item at a time
var current_held_item: Node = null
var held_item_scene_path: String = ""

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
	# Reload R (only if holding ranged weapon)
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reload_current_item()
	# Drop item G
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		drop_held_item()

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
	# Update held item UI
	update_held_item_ui()
	# Attack check - left click
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dodging and hit_stun_timer <= 0.0:
		handle_attack()
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

func handle_attack() -> void:
	# If holding weapon, use weapon attack
	if current_held_item != null and current_held_item.has_method("can_attack") and current_held_item.can_attack():
		current_held_item.attack()
		return
	# If holding tool (wrench), cannot attack
	if current_held_item != null and current_held_item.has_method("can_attack") and not current_held_item.can_attack():
		return
	# Empty hand - punch
	if current_held_item == null and punch_cd_timer <= 0.0:
		start_punch()

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

# ============================================================
# Holdable Item System
# ============================================================

func pick_up_item(item: Node) -> void:
	if item == null:
		return
	# If already holding something, drop it first
	if current_held_item != null:
		drop_held_item()
	# Pick up new item
	current_held_item = item
	if item.has_method("get_path"):
		held_item_scene_path = item.scene_file_path
	if item.has_method("pick_up"):
		item.pick_up(self)
	# Attach to weapon mount
	var mount: Node3D = get_node("Head/WeaponMount") as Node3D
	if mount != null:
		if item.get_parent() != null:
			item.get_parent().remove_child(item)
		mount.add_child(item)
		item.position = Vector3(0.3, -0.2, -0.5)
		item.visible = true
	# Set owner for weapons
	if item.has_method("set_owner_player"):
		item.set_owner_player(self)

func drop_held_item() -> void:
	if current_held_item == null:
		return
	var item: Node = current_held_item
	var item_path: String = held_item_scene_path
	# Get drop position in front of player
	var drop_pos: Vector3 = global_position + -global_transform.basis.z * 1.5
	drop_pos.y = 0.5
	# If it's a weapon, spawn a weapon pickup
	if item.has_method("set_owner_player") and item_path != "":
		var pickup_scene: PackedScene = load("res://modules/weapon/weapon_pickup.tscn")
		var loaded_scene: PackedScene = load(item_path)
		if pickup_scene != null and loaded_scene != null:
			var pickup: Node = pickup_scene.instantiate()
			pickup.weapon_scene = loaded_scene
			if item.has_method("weapon_name"):
				pickup.weapon_name = item.weapon_name
			pickup.position = drop_pos
			get_tree().current_scene.add_child(pickup)
	# If it's a tool (wrench), spawn it directly
	elif "interact_tag" in item:
		if item.get_parent() != null:
			item.get_parent().remove_child(item)
		get_tree().current_scene.add_child(item)
		item.global_position = drop_pos
		if item.has_method("drop"):
			item.drop(drop_pos)
	# Clear reference
	current_held_item = null
	held_item_scene_path = ""
	# Free weapon if it was attached
	if item.has_method("set_owner_player"):
		item.queue_free()

func reload_current_item() -> void:
	if current_held_item == null:
		return
	if current_held_item.has_method("reload"):
		current_held_item.reload()

func get_current_interact_tag() -> String:
	# Returns the tool tag of currently held item, empty if no tool
	if current_held_item == null:
		return ""
	if current_held_item.has_method("interact_tag"):
		return current_held_item.interact_tag
	if "interact_tag" in current_held_item:
		return current_held_item.interact_tag
	return ""

func is_holding_tool() -> bool:
	if current_held_item == null:
		return false
	if "interact_tag" in current_held_item:
		return current_held_item.item_type == 0
	return false

func is_holding_weapon() -> bool:
	if current_held_item == null:
		return false
	return current_held_item.has_method("set_owner_player")

func update_held_item_ui() -> void:
	if current_held_item == null:
		UIManager.update_weapon_ui("空手")
		UIManager.set_crosshair_visible(false)
		return
	# Weapon
	if current_held_item.has_method("set_owner_player"):
		var w_name: String = "武器"
		if current_held_item.has_method("weapon_name"):
			w_name = current_held_item.weapon_name
		if current_held_item.has_method("reload"):
			var ammo: int = current_held_item.current_ammo
			var max_a: int = current_held_item.mag_size
			UIManager.update_weapon_ui(w_name, ammo, max_a)
			UIManager.set_crosshair_visible(true)
		else:
			UIManager.update_weapon_ui(w_name)
			UIManager.set_crosshair_visible(false)
		return
	# Tool
	if "interact_tag" in current_held_item:
		UIManager.update_weapon_ui(current_held_item.item_name)
		UIManager.set_crosshair_visible(false)
		return
	UIManager.update_weapon_ui("物品")
	UIManager.set_crosshair_visible(false)

# ============================================================
# Legacy weapon system compatibility (for weapon_pickup)
# ============================================================

func equip_weapon(weapon: Node) -> void:
	pick_up_item(weapon)

func switch_weapon(index: int) -> void:
	# No longer used - one item at a time
	pass
