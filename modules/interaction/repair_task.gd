extends Area3D
class_name RepairTask

@export var task_name: String = "修理任务"
@export var repair_speed_per_player: float = 10.0
@export var required_progress: float = 100.0
@export var interaction_key: Key = KEY_E

signal repair_completed()
signal repair_progress_changed(progress: float, total: float)

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
	# 按住E持续修理，多人同时修速度叠加
	var active_players: int = 0
	for player in interacting_players:
		if player != null and is_instance_valid(player):
			if Input.is_key_pressed(interaction_key):
				active_players += 1
	if active_players > 0:
		current_progress += repair_speed_per_player * active_players * delta
		repair_progress_changed.emit(current_progress, required_progress)
		if current_progress >= required_progress:
			current_progress = required_progress
			complete_repair()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.append(player)

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		var player: Player = body as Player
		interacting_players.erase(player)

func complete_repair() -> void:
	if is_completed:
		return
	is_completed = true
	repair_completed.emit()

func get_progress_percent() -> float:
	if required_progress <= 0:
		return 1.0
	return current_progress / required_progress
