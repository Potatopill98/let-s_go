extends StaticBody3D
class_name ElevatorPlatform

@export var rise_speed: float = 3.0
@export var target_height: float = 12.0
@export var countdown_time: float = 15.0

var is_activated: bool = false
var is_rising: bool = false
var has_arrived: bool = false
var countdown_timer: float = 0.0
var original_y: float = 0.0
var target_y: float = 0.0
var last_position: Vector3 = Vector3.ZERO

signal countdown_started(time_left: float)
signal countdown_tick(time_left: float)
signal platform_risen()

func _ready() -> void:
	original_y = position.y
	target_y = original_y + target_height
	last_position = position
	add_to_group("elevator")
	countdown_started.connect(func(t): UIManager.show_countdown(t))
	countdown_tick.connect(func(t): UIManager.show_countdown(t))
	platform_risen.connect(func(): UIManager.hide_countdown())

func _physics_process(delta: float) -> void:
	if is_activated and not is_rising:
		countdown_timer -= delta
		countdown_tick.emit(countdown_timer)
		if countdown_timer <= 0.0:
			is_rising = true
			last_position = position
	if is_rising:
		var old_pos: Vector3 = position
		position.y = move_toward(position.y, target_y, rise_speed * delta)
		var move_delta: Vector3 = position - old_pos
		# 带动站在平台上的玩家
		var players: Array = get_tree().get_nodes_in_group("player")
		for p in players:
			var player: Player = p as Player
			if player == null:
				continue
			# 检测玩家是否站在平台上
			var player_bottom: float = player.global_position.y
			var platform_top: float = global_position.y + 0.3
			if abs(player_bottom - platform_top) < 0.5:
				var player_horizontal: Vector2 = Vector2(player.global_position.x, player.global_position.z)
				var platform_horizontal: Vector2 = Vector2(global_position.x, global_position.z)
				if player_horizontal.distance_to(platform_horizontal) < 4.0:
					player.global_position += move_delta
		if position.y >= target_y - 0.01 and not has_arrived:
			position.y = target_y
			is_rising = false
			has_arrived = true
			# 把站在平台上的玩家传送到第三层地面，避免被碰撞挤下来
			var all_players: Array = get_tree().get_nodes_in_group("player")
			for p in all_players:
				var player: Player = p as Player
				if player == null:
					continue
				var player_bottom: float = player.global_position.y
				var platform_top: float = global_position.y + 0.3
				if abs(player_bottom - platform_top) < 1.0:
					var player_horizontal: Vector2 = Vector2(player.global_position.x, player.global_position.z)
					var platform_horizontal: Vector2 = Vector2(global_position.x, global_position.z)
					if player_horizontal.distance_to(platform_horizontal) < 4.0:
						player.global_position = Vector3(player.global_position.x, target_y + 0.5, player.global_position.z)
			platform_risen.emit()
			UIManager.show_message("已到达第三层安全区！")

func activate() -> void:
	if is_activated:
		return
	is_activated = true
	countdown_timer = countdown_time
	countdown_started.emit(countdown_timer)

func reset() -> void:
	is_activated = false
	is_rising = false
	countdown_timer = 0.0
	position.y = original_y



