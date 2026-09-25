extends CharacterBody3D
class_name Player

# 基础移动参数
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
# 闪避参数
@export var dodge_speed: float = 12.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.0
# 挥拳参数
@export var punch_damage: float = 5.0
@export var punch_cooldown: float = 1.0
# 生命参数
@export var max_health: float = 100.0
var current_health: float = 100.0
@export var hit_stun_duration: float = 0.2

# 内部状态
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_move_speed: float = 5.0
var dodge_timer: float = 0.0
var dodge_cd_timer: float = 0.0
var is_dodging: bool = false
var punch_cd_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var hit_stun_timer: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head.position.y = 1.6
	current_move_speed = walk_speed
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	# 受击硬直期间不响应输入
	if hit_stun_timer > 0.0:
		return
	# 鼠标视角
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.0 + 0.01, PI / 2.0 - 0.01)
	# ESC切换鼠标
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# 闪避触发
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q and dodge_cd_timer <= 0.0 and not is_dodging and is_on_floor():
		start_dodge()

func _physics_process(delta: float) -> void:
	# 计时器递减
	if dodge_cd_timer > 0.0:
		dodge_cd_timer -= delta
	if punch_cd_timer > 0.0:
		punch_cd_timer -= delta
	if hit_stun_timer > 0.0:
		hit_stun_timer -= delta
	# 挥拳检测
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and punch_cd_timer <= 0.0 and not is_dodging and hit_stun_timer <= 0.0:
		start_punch()
	# 受击硬直期间只应用重力和击退，不覆盖移动速度
	if hit_stun_timer > 0.0:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	# 闪避逻辑优先
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
		if dodge_timer <= 0.0:
			is_dodging = false
	else:
		# 正常移动逻辑
		if not is_on_floor():
			velocity.y -= gravity * delta
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		# 奔跑切换
		if Input.is_key_pressed(KEY_SHIFT):
			current_move_speed = run_speed
		else:
			current_move_speed = walk_speed
		# WASD输入
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var move_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = move_dir.x * current_move_speed
		velocity.z = move_dir.z * current_move_speed
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
	# 正常前方范围判定：3米内，正面120度角，命中最近怪物
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	var hit_monster: BaseMonster = null
	var min_dist: float = 3.0
	var face_dir: Vector3 = -global_transform.basis.z
	face_dir.y = 0.0
	face_dir = face_dir.normalized()
	for node in monsters:
		var m: BaseMonster = node as BaseMonster
		if m == null or m.is_dead:
			continue
		var to_monster: Vector3 = m.global_position - global_position
		to_monster.y = 0.0
		var dist: float = to_monster.length()
		if dist >= min_dist:
			continue
		# 120度角判定
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

# 受伤接口
func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0.0:
		return
	current_health -= amount
	# 应用击退并进入受击硬直
	velocity += knockback
	hit_stun_timer = hit_stun_duration
	if current_health <= 0.0:
		current_health = 0.0

