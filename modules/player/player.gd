extends CharacterBody3D
class_name Player
const InventoryScript = preload("res://modules/player/inventory.gd")
const EquipmentScript = preload("res://modules/player/equipment_manager.gd")
const ThrowableScript = preload("res://modules/weapon/throwable.gd")

# ============================================================
# Player Controller with Holdable Item System
# One hand, one item at a time
# Empty hand: can punch
# Tool: can interact, cannot attack
# Weapon: can attack, cannot repair
# ============================================================

# Movement params
@export var walk_speed: float = 10.0
@export var run_speed: float = 16.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
# Dodge params
@export var dodge_speed: float = 24.0
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
# Downed / death state
var is_downed: bool = false
var is_dead: bool = false
var downed_bleed_timer: float = 100.0
var downed_crawl_speed: float = 1.5
var revive_health: float = 30.0
var nearby_downed_player: Node = null
var revive_prompt_shown: bool = false

# Holdable item system - one item at a time
var current_held_item: Node = null
var held_item_scene_path: String = ""

# Inventory system - 6 slots (2 task + 4 consumable)
var inventory: Node = null
# Equipment system - head/body/feet
var equipment: Node = null

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var left_leg_pivot: Node3D = $LeftLegPivot
@onready var right_leg_pivot: Node3D = $RightLegPivot
@onready var left_arm_pivot: Node3D = $Head/LeftArmPivot
@onready var right_arm: MeshInstance3D = $Head/RightArm
var walk_cycle: float = 0.0
var walk_anim_speed: float = 10.0
var _last_step_cycle: float = 0.0
var walk_leg_amp: float = 0.5
var walk_arm_amp: float = 0.35

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head.position.y = 1.6
	current_move_speed = walk_speed
	add_to_group("player")
	# Initialize inventory
	inventory = InventoryScript.new()
	inventory.name = "Inventory"
	add_child(inventory)
	inventory.inventory_changed.connect(_on_inventory_changed)
	# Initialize equipment
	equipment = EquipmentScript.new()
	equipment.name = "Equipment"
	add_child(equipment)
	equipment.equipment_changed.connect(_on_equipment_changed)
	# 初始化UI
	update_inventory_ui()
	if UIManager != null:
		UIManager.update_equipment(equipment.get_equipment_list())

func _input(event: InputEvent) -> void:
	# Mouse look - highest priority, always works even when repairing
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.0 + 0.01, PI / 2.0 - 0.01)

func _unhandled_input(event: InputEvent) -> void:
	# Skip most input when downed/dead
	if is_downed or is_dead:
		return
	# Revive teammate with E
	if event.is_action_pressed("interact"):
		_try_revive()
		return
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
	# Use consumable 1-4
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			use_inventory_consumable(0)
		elif event.keycode == KEY_2:
			use_inventory_consumable(1)
		elif event.keycode == KEY_3:
			use_inventory_consumable(2)
		elif event.keycode == KEY_4:
			use_inventory_consumable(3)
		elif event.keycode == KEY_F:
			throw_held_item()
		elif event.keycode == KEY_V:
			place_held_item()

func _physics_process(delta: float) -> void:
	# Timers
	if dodge_cd_timer > 0.0:
		dodge_cd_timer -= delta
	if punch_cd_timer > 0.0:
		punch_cd_timer -= delta
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
	# Update UI health
	if UIManager != null and UIManager.has_method("update_health"):
		UIManager.update_health(current_health, max_health)
	# Update held item UI
	update_held_item_ui()
	# Check for nearby downed teammate to revive
	_check_downed_teammate()
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
			if AudioManager != null:
				AudioManager.play_sfx("jump", 0.5)
		# Run
		if Input.is_key_pressed(KEY_SHIFT):
			current_move_speed = run_speed
		else:
			current_move_speed = walk_speed
	move_and_slide()
	_update_walk_animation(delta)

func _update_walk_animation(delta: float) -> void:
	if is_downed or is_dead:
		return
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var is_moving: bool = horizontal_speed > 0.5
	if is_moving:
		var speed_factor: float = clampf(horizontal_speed / walk_speed, 0.5, 2.0)
		walk_cycle += delta * walk_anim_speed * speed_factor
		# 每步播放脚步声 (walk_cycle每经过PI走一步)
		if int(walk_cycle / PI) > int(_last_step_cycle / PI):
			if AudioManager != null:
				AudioManager.play_sfx("footstep", 0.4)
		_last_step_cycle = walk_cycle
		var leg_swing: float = sin(walk_cycle) * walk_leg_amp
		var arm_swing: float = sin(walk_cycle + PI) * walk_arm_amp
		left_leg_pivot.rotation.x = leg_swing
		right_leg_pivot.rotation.x = -leg_swing
		left_arm_pivot.rotation.x = arm_swing
		# 右手臂只在空手时摆动, 拿武器时不摆
		if current_held_item == null:
			right_arm.rotation.x = 0.5 + (-arm_swing)
	else:
		walk_cycle = 0.0
		left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, delta * 10.0)
		right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, delta * 10.0)
		left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, 0.0, delta * 10.0)
		if current_held_item == null:
			right_arm.rotation.x = lerp(right_arm.rotation.x, 0.5, delta * 10.0)

func handle_attack() -> void:
	if is_downed or is_dead:
		return
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
	if AudioManager != null:
		AudioManager.play_sfx("whoosh", 0.7)
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
	if AudioManager != null:
		AudioManager.play_sfx("punch_swing", 0.6)
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	var hit_monster: Node = null
	var min_dist: float = 3.0
	var face_dir: Vector3 = -global_transform.basis.z
	face_dir.y = 0.0
	face_dir = face_dir.normalized()
	for node in monsters:
		var m: Node = node
		if not is_instance_valid(m) or m.is_dead:
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
		if AudioManager != null:
			AudioManager.play_sfx("punch_hit", 0.8)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	# Already downed: monsters reduce bleed-out timer, no knockback
	if is_downed:
		downed_bleed_timer -= amount
		if downed_bleed_timer <= 0.0:
			_die()
		return
	# Apply equipment damage resistance
	var actual_damage: float = amount
	if equipment != null:
		var resist: float = equipment.get_damage_resistance()
		actual_damage = amount * (1.0 - resist)
	current_health -= actual_damage
	velocity += knockback
	hit_stun_timer = hit_stun_duration
	if UIManager != null:
		UIManager.flash_damage()
	if AudioManager != null:
		AudioManager.play_sfx("player_hurt", 0.8)
	if current_health <= 0.0:
		_enter_downed()

func _enter_downed() -> void:
	is_downed = true
	if AudioManager != null:
		AudioManager.play_sfx("body_fall", 0.9)
	current_health = 0.0
	downed_bleed_timer = 100.0
	velocity = Vector3.ZERO
	# Lower camera to ground
	head.position.y = 0.5
	if UIManager != null:
		UIManager.show_announcement("你已倒地 - 等待队友救援", 3.0)
	print("[Player] 进入倒地状态，100秒内需要救援")

func _check_downed_teammate() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	var found: Node = null
	for p in players:
		if p == self:
			continue
		if p.is_downed and not p.is_dead:
			var d: float = global_position.distance_to(p.global_position)
			if d <= 2.5:
				found = p
				break
	nearby_downed_player = found
	if found != null:
		if not revive_prompt_shown:
			revive_prompt_shown = true
			if UIManager != null:
				UIManager.show_interaction_prompt("按E - 救起队友 (%.0f秒)" % found.downed_bleed_timer)
		else:
			if UIManager != null:
				UIManager.show_interaction_prompt("按E - 救起队友 (%.0f秒)" % found.downed_bleed_timer)
	else:
		if revive_prompt_shown:
			revive_prompt_shown = false
			if UIManager != null:
				UIManager.hide_interaction_prompt()

func _try_revive() -> void:
	if nearby_downed_player != null and is_instance_valid(nearby_downed_player):
		nearby_downed_player.revive_player()
		nearby_downed_player = null
		revive_prompt_shown = false
		if UIManager != null:
			UIManager.hide_interaction_prompt()
func revive_player() -> void:
	if not is_downed:
		return
	is_downed = false
	current_health = revive_health
	head.position.y = 1.6
	if UIManager != null:
		UIManager.show_announcement("已被队友救起", 2.0)
	print("[Player] 被队友救起")

func _die() -> void:
	is_dead = true
	is_downed = false
	head.position.y = 0.3
	if UIManager != null:
		UIManager.show_announcement("你已死亡", 3.0)
	print("[Player] 死亡出局")

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
	if AudioManager != null:
		AudioManager.play_sfx("item_pickup", 0.7)
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
	if AudioManager != null:
		AudioManager.play_sfx("item_pickup", 0.5, 0.8)
	var item: Node = current_held_item
	var item_path: String = held_item_scene_path
	# Get drop position in front of player, use player's Y so it lands on current floor
	var drop_pos: Vector3 = global_position + -global_transform.basis.z * 1.5
	drop_pos.y = global_position.y - 0.3
	# Get item name
	var drop_item_name: String = "物品"
	if item.has_method("weapon_name"):
		drop_item_name = item.weapon_name
	elif "item_name" in item:
		drop_item_name = item.item_name
	# Spawn unified item pickup (works for both weapons and tools)
	if item_path != "":
		var pickup_scene: PackedScene = load("res://modules/item/item_pickup.tscn")
		var loaded_scene: PackedScene = load(item_path)
		if pickup_scene != null and loaded_scene != null:
			var pickup: Node = pickup_scene.instantiate()
			pickup.item_scene = loaded_scene
			pickup.item_name = drop_item_name
			pickup.position = drop_pos
			get_tree().current_scene.add_child(pickup)
	# Clear reference
	current_held_item = null
	held_item_scene_path = ""
	# Free the held item instance
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

func has_held_item(tag: String) -> bool:
	# 检查当前手持物品的interact_tag是否匹配
	if current_held_item == null:
		return false
	var current_tag: String = ""
	if current_held_item.has_method("interact_tag"):
		current_tag = current_held_item.interact_tag
	elif "interact_tag" in current_held_item:
		current_tag = current_held_item.interact_tag
	return current_tag == tag

func is_holding_weapon() -> bool:
	if current_held_item == null:
		return false
	return current_held_item.has_method("set_owner_player")

func update_held_item_ui() -> void:
	if UIManager == null:
		return
	if current_held_item == null:
		UIManager.update_item_ui("空手")
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
			UIManager.update_item_ui(w_name, ammo, max_a)
			UIManager.set_crosshair_visible(true)
		else:
			UIManager.update_item_ui(w_name)
			UIManager.set_crosshair_visible(false)
		return
	# Tool
	if "interact_tag" in current_held_item:
		UIManager.update_item_ui(current_held_item.item_name)
		UIManager.set_crosshair_visible(false)
		return
	UIManager.update_item_ui("物品")
	UIManager.set_crosshair_visible(false)

# ============================================================
# Legacy weapon system compatibility (for weapon_pickup)
# ============================================================

func equip_weapon(weapon: Node) -> void:
	pick_up_item(weapon)

func switch_weapon(index: int) -> void:
	# No longer used - one item at a time
	pass


# ============================================================
# Inventory System
# ============================================================

func _on_inventory_changed() -> void:
	update_inventory_ui()

func update_inventory_ui() -> void:
	if UIManager == null:
		return
	if inventory == null:
		return
	# Update UI with inventory data
	var task_items: Array = inventory.get_task_items()
	var consumable_data: Array = []
	for i in range(4):
		var slot: Dictionary = inventory.get_consumable(i)
		if not slot.is_empty():
			var item_id: String = slot.get("item_id", "")
			var count: int = slot.get("count", 0)
			consumable_data.append({"item_id": item_id, "count": count, "name": ItemManager.get_item_name(item_id)})
		else:
			consumable_data.append({})
	UIManager.update_inventory(task_items, consumable_data)

func use_inventory_consumable(slot_index: int) -> void:
	if inventory == null:
		return
	var data: Dictionary = inventory.use_consumable(slot_index)
	if data.is_empty():
		return
	var item_id: String = data.get("item_id", "")
	var subtype: String = data.get("item_subtype", "")
	# Apply effect based on subtype
	if subtype == "heal":
		var heal_amount: float = data.get("heal_amount", 0)
		heal(heal_amount)
		UIManager.show_toast("使用了 " + ItemManager.get_item_name(item_id) + "，回血" + str(heal_amount))
	elif subtype == "buff":
		var speed_mult: float = data.get("speed_mult", 1.0)
		var buff_duration: float = data.get("buff_duration", 0)
		if speed_mult > 1.0:
			current_move_speed = run_speed * speed_mult
			UIManager.show_toast("使用了 " + ItemManager.get_item_name(item_id) + "，移速提升")
	elif subtype == "ammo":
		var ammo_type: String = data.get("ammo_type", "")
		var ammo_amount: int = data.get("ammo_amount", 0)
		UIManager.show_toast("使用了 " + ItemManager.get_item_name(item_id))

func pickup_inventory_item(item_id: String) -> bool:
	if inventory == null:
		return false
	if not ItemManager.has_item(item_id):
		return false
	var data: Dictionary = ItemManager.get_item_data(item_id)
	var item_type: String = data.get("item_type", "")
	if item_type == "inventory_task":
		return inventory.add_task_item(item_id)
	elif item_type == "inventory_consumable":
		return inventory.add_consumable(item_id, 1)
	return false

func has_task_item(item_id: String) -> bool:
	if inventory == null:
		return false
	return inventory.has_task_item(item_id)

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	UIManager.update_health(current_health, max_health)


# ============================================================
# Equipment System
# ============================================================

func _on_equipment_changed(slot: int, item_id: String) -> void:
	update_equipment_ui()

func update_equipment_ui() -> void:
	if UIManager == null:
		return
	if equipment == null:
		return
	var equip_list: Array = equipment.get_equipment_list()
	UIManager.update_equipment(equip_list)

func equip_item(item_id: String) -> bool:
	if equipment == null:
		return false
	return equipment.equip(item_id)

func unequip_slot(slot: int) -> String:
	if equipment == null:
		return ""
	return equipment.unequip(slot)

func has_equipment_immunity(status_type: String) -> bool:
	if equipment == null:
		return false
	return equipment.has_immunity(status_type)

func get_equipment_speed_modifier() -> float:
	if equipment == null:
		return 1.0
	return equipment.get_speed_modifier()

# ============================================================
# Throwable System
# ============================================================

func throw_held_item() -> void:
	# 检查背包中是否有投掷物
	if inventory == null:
		return
	var throwable_id: String = ""
	for i in range(4):
		var slot: Dictionary = inventory.get_consumable(i)
		if not slot.is_empty():
			var item_id: String = slot.get("item_id", "")
			var data: Dictionary = ItemManager.get_item_data(item_id)
			if data.get("item_subtype", "") == "throwable":
				throwable_id = item_id
				inventory.use_consumable(i)
				break
	if throwable_id == "":
		return
	# 生成投掷物
	var throwable_scene: PackedScene = load("res://modules/weapon/throwable.tscn")
	if throwable_scene == null:
		return
	var throwable: Node = throwable_scene.instantiate()
	var data: Dictionary = ItemManager.get_item_data(throwable_id)
	throwable.throw_item_id = throwable_id
	throwable.damage = data.get("damage", 5.0)
	throwable.explosion_radius = data.get("explosion_radius", 0.0)
	throwable.explosion_damage = data.get("explosion_damage", 0.0)
	throwable.attract_monsters = data.get("attract_monsters", false)
	throwable.attract_duration = data.get("attract_duration", 0.0)
	throwable.thrower = self
	# 设置颜色
	var mesh_inst: MeshInstance3D = throwable.get_node("Mesh")
	if mesh_inst != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = data.get("color", Color.WHITE)
		mesh_inst.material_override = mat
	# 从相机前方抛出
	var throw_pos: Vector3 = camera.global_position + camera.global_transform.basis.z * 0.5
	var throw_dir: Vector3 = -camera.global_transform.basis.z
	throw_dir.y += 0.2
	throw_dir = throw_dir.normalized()
	get_tree().current_scene.add_child(throwable)
	throwable.throw_from(throw_pos, throw_dir, 15.0)
	UIManager.show_toast("投掷了 " + ItemManager.get_item_name(throwable_id))

# ============================================================
# Placeable System
# ============================================================

func place_held_item() -> void:
	if inventory == null:
		return
	# 找背包中的放置物
	var placeable_id: String = ""
	for i in range(4):
		var slot: Dictionary = inventory.get_consumable(i)
		if not slot.is_empty():
			var item_id: String = slot.get("item_id", "")
			var data: Dictionary = ItemManager.get_item_data(item_id)
			if data.get("item_type", "") == "placeable":
				placeable_id = item_id
				inventory.use_consumable(i)
				break
	if placeable_id == "":
		return
	# 生成放置物
	var placeable_scene: PackedScene = load("res://modules/item/placeable.tscn")
	if placeable_scene == null:
		return
	var placeable: Node = placeable_scene.instantiate()
	var data: Dictionary = ItemManager.get_item_data(placeable_id)
	placeable.place_item_id = placeable_id
	placeable.duration = data.get("duration", 60.0)
	placeable.is_turret = data.get("is_turret", false)
	placeable.turret_damage = data.get("damage", 10.0)
	placeable.turret_range = data.get("turret_range", 15.0)
	placeable.is_trap = data.get("is_trap", false)
	placeable.trap_damage = data.get("damage", 20.0)
	placeable.is_light = data.get("is_light", false)
	placeable.light_range = data.get("light_range", 10.0)
	placeable.light_color = data.get("color", Color(0.5, 1.0, 0.5))
	placeable.is_barricade = data.get("is_barricade", false)
	placeable.barricade_health = data.get("health", 100.0)
	# 放在玩家前方2米
	var place_pos: Vector3 = global_position + -global_transform.basis.z * 2.0
	place_pos.y = global_position.y - 0.5
	get_tree().current_scene.add_child(placeable)
	placeable.global_position = place_pos
	UIManager.show_toast("放置了 " + ItemManager.get_item_name(placeable_id))