extends CharacterBody3D
class_name ElevatorPlatform

@export var rise_speed: float = 2.0
@export var target_height: float = 10.0
@export var countdown_time: float = 10.0
@export var platform_size: Vector2 = Vector2(6, 6)

var is_activated: bool = false
var is_rising: bool = false
var countdown_timer: float = 0.0
var original_y: float = 0.0
var target_y: float = 0.0

signal countdown_started(time_left: float)
signal countdown_tick(time_left: float)
signal platform_risen()
signal player_left_behind()

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	original_y = position.y
	target_y = original_y + target_height
	add_to_group("elevator")
	# 动态连接UI，避免场景加载顺序问题
	countdown_started.connect(func(t): UIManager.show_countdown(t))
	countdown_tick.connect(func(t): UIManager.show_countdown(t))
	platform_risen.connect(func(): UIManager.hide_countdown())

func _physics_process(delta: float) -> void:
	if is_activated and not is_rising:
		# 倒计时阶段
		countdown_timer -= delta
		countdown_tick.emit(countdown_timer)
		if countdown_timer <= 0.0:
			is_rising = true
	if is_rising:
		# 上升阶段
		position.y = move_toward(position.y, target_y, rise_speed * delta)
		# 带动站在平台上的玩家
		move_and_slide()
		if position.y >= target_y - 0.01:
			position.y = target_y
			is_rising = false
			platform_risen.emit()

# 修理完成后调用，启动倒计时
func activate() -> void:
	if is_activated:
		return
	is_activated = true
	countdown_timer = countdown_time
	countdown_started.emit(countdown_timer)

# 重置平台（用于测试）
func reset() -> void:
	is_activated = false
	is_rising = false
	countdown_timer = 0.0
	position.y = original_y

