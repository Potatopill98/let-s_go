extends Area3D
class_name Interactable

# 交互模式
enum InteractionMode {
	PRESS, # 按一下触发
	HOLD # 按住持续触发
}

@export var interaction_mode: InteractionMode = InteractionMode.HOLD
@export var interaction_key: Key = KEY_E
@export var max_progress: float = 100.0
@export var interaction_speed_per_player: float = 10.0 # 每个玩家每秒增加的进度
@export var interaction_prompt: String = "按E交互"

# 信号
signal interaction_started(player: Player)
signal interaction_progress_changed(progress: float)
signal interaction_completed()
signal player_entered(player: Player)
signal player_exited(player: Player)

var current_progress: float = 0.0
var interacting_players: Array = []
var is_completed: bool = false

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_completed:
		return
	# 按住模式：持续计算所有正在交互玩家的进度
	if interaction_mode == InteractionMode.HOLD:
		var active_players: int = 0
		for player in interacting_players:
			if player != null and is_instance_valid(player):
				if Input.is_key_pressed(interaction_key):
					active_players += 1
		if active_players > 0:
			current_progress += interaction_speed_per_player * active_players * delta
			interaction_progress_changed.emit(current_progress)
			if current_progress >= max_progress:
				current_progress = max_progress
				complete_interaction()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.append(player)
		player_entered.emit(player)
		# 按一下模式：进入区域按E直接触发
		if interaction_mode == InteractionMode.PRESS:
			# 等待玩家按键
			pass

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.erase(player)
		player_exited.emit(player)

func _unhandled_input(event: InputEvent) -> void:
	if is_completed:
		return
	# 按一下模式：在区域内按E触发
	if interaction_mode == InteractionMode.PRESS:
		if event is InputEventKey and event.pressed and event.keycode == interaction_key:
			for player in interacting_players:
				if player != null and is_instance_valid(player):
					complete_interaction()
					return

func complete_interaction() -> void:
	if is_completed:
		return
	is_completed = true
	interaction_completed.emit()
